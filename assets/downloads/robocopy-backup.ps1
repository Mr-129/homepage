<#
PowerShell バックアップスクリプト

Usage:
    - シミュレーション（実際のファイル操作は行わない）
            powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\copy.ps1"
        または PowerShell セッション内から実行:
            & "$PSScriptRoot\copy.ps1"
        ※シミュレーションは `-Run` を指定しません。

    - 本番実行（コピーを行う）
            powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\copy.ps1" -Run

    - 資格情報を使って実行する場合（例）
            $cred = Get-Credential
            & "$PSScriptRoot\copy.ps1" -Run -Credential $cred

    - ログ保存先や robocopy オプションを指定する例:
            & "$PSScriptRoot\copy.ps1" -Run -LogDir 'C:\Logs' -CopyMode E -Threads 8 -ExtraOptions @('/XO','/FFT')

    - ログ保存先が UNC で資格情報が必要な場合（例）:
        $logCred = Get-Credential
        & "$PSScriptRoot\copy.ps1" -Run -LogDir "\\server\share\logs" -LogCredential $logCred

Notes:
    - デフォルトではミラーリング（/MIR）です。必要に応じて `-CopyMode` を変更してください。
    - 実行前に `-Source` / `-Destination` を確認してください。誤指定による削除リスクがあります。
#>

# --- スクリプト引数定義 ---
# $Source: コピー元のパス（既定値は作成時のユーザーの例）
# $Destination: コピー先のネットワーク共有パス
# $CopyMode: robocopy のコピー方式（MIR/E/S）
# $Threads: 本番時のスレッド数
# $SimThreads: シミュレーション時のスレッド数
# $Retries: 再試行回数（/R）
# $Wait: 再試行待機秒（/W）
# $Restartable: /Z を使うか
# $ExtraOptions: 追加の robocopy オプション
# $Run: スイッチ。付けない場合はシミュレーション（実行せずログのみ）
# $Credential: ネットワーク共有に接続する資格情報（Get-Credential の戻り値）
# $LogCredential: ログ保存先に接続する資格情報（Get-Credential の戻り値）
param(
    [string]$Source = "C:\Backup\Source",
    [string]$Destination = "\\SERVER\share\backup",
    [string]$LogDir = (Join-Path $env:TEMP 'backup_logs'),
    [ValidateSet('MIR','E','S')][string]$CopyMode = 'MIR',
    [int]$Threads = 16,
    [int]$SimThreads = 4,
    [int]$Retries = 3,
    [int]$Wait = 5,
    [switch]$Restartable,
    [string[]]$ExtraOptions = @(),
    [switch]$Run,
    [System.Management.Automation.PSCredential]$Credential,
    [System.Management.Automation.PSCredential]$LogCredential
)

# --- 空いているドライブ文字を取得する関数 ---
# ネットワーク共有を一時的にマッピングする際に使用します。
function Get-FreeDriveLetter {
    # 既に使われているドライブ名一覧を取得
    $used = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name
    # 末尾から探す（Z から）ことで一般的な空き文字を優先
    $letters = 'Z','Y','X','W','V','U','T','S','R','Q','P','O','N','M','L','K','J','I','H','G','F','E','D'
    foreach ($l in $letters) { if ($used -notcontains $l) { return "$($l):" } }
    throw '空いているドライブ文字が見つかりません。'
}

# --- ログディレクトリとログファイルパス ---
$logDrive = $null
$logDirResolved = $LogDir
$simLog = $null
$runLog = $null

# --- ログ追記用の簡易関数 ---
function Write-StatusLog {
    param(
        [string]$Path,
        [string]$Message
    )
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try {
        Add-Content -LiteralPath $Path -Value "[$ts] $Message" -ErrorAction Stop
    } catch {
        Write-Error "[LOG-FALLBACK] $Message (log write failed: $($_.Exception.Message))"
    }
}

# --- パス妥当性チェック ---
if ([string]::IsNullOrWhiteSpace($Source)) {
    throw 'Source が空です。'
}
if ([string]::IsNullOrWhiteSpace($Destination)) {
    throw 'Destination が空です。'
}
if (-not (Test-Path -LiteralPath $Source)) {
    throw "Source が存在しません: $Source"
}
$sourceItem = Get-Item -LiteralPath $Source -ErrorAction Stop
if (-not $sourceItem.PSIsContainer) {
    throw "Source がフォルダではありません: $Source"
}
if (($Source.TrimEnd('\')) -ieq ($Destination.TrimEnd('\'))) {
    throw 'Source と Destination が同一です。'
}
if (-not $Credential) {
    if (-not (Test-Path -LiteralPath $Destination)) {
        throw "Destination が存在しません: $Destination"
    }
}


# --- メイン処理: ネットワーク共有に認証情報がある場合は一時マッピング ---
$mappedDrive = $null
try {
    if ($LogCredential -and ($LogDir -like '\\\\*')) {
        $logDrive = Get-FreeDriveLetter
        $uncRoot = $LogDir
        $uncSub = $null
        if ($LogDir -match '^(\\\\[^\\]+\\[^\\]+)(\\.*)?$') {
            $uncRoot = $Matches[1]
            $uncSub = $Matches[2]
        }
        New-PSDrive -Name $logDrive.TrimEnd(':') -PSProvider FileSystem -Root $uncRoot -Credential $LogCredential -ErrorAction Stop | Out-Null
        if ([string]::IsNullOrEmpty($uncSub)) {
            $logDirResolved = $logDrive + '\\'
        } else {
            $logDirResolved = Join-Path $logDrive ($uncSub.TrimStart('\\'))
        }
    }
    if (-not (Test-Path $logDirResolved)) { New-Item -Path $logDirResolved -ItemType Directory -Force | Out-Null }
    $logMonthDir = Join-Path $logDirResolved (Get-Date -Format 'yyyyMM')
    if (-not (Test-Path $logMonthDir)) { New-Item -Path $logMonthDir -ItemType Directory -Force | Out-Null }
    $logDay = Get-Date -Format 'yyyyMMdd'
    $simLog = Join-Path $logMonthDir ("backup_sim_{0}.log" -f $logDay)
    $runLog = Join-Path $logMonthDir ("backup_copy_{0}.log" -f $logDay)

    if ($Credential) {
        # 空きドライブ文字を取得して New-PSDrive でマッピング
        $drive = Get-FreeDriveLetter
        New-PSDrive -Name $drive.TrimEnd(':') -PSProvider FileSystem -Root $Destination -Credential $Credential -ErrorAction Stop | Out-Null
        $mappedDrive = $drive
        # Robocopy に渡す際のパス（例: "Z:\"）
        $destForRobo = "$mappedDrive\\"
    } else {
        # 直接 UNC パスを使用
        $destForRobo = $Destination
    }

    Write-Output "[INFO] Source: $Source"
    Write-Output "[INFO] Destination: $Destination"
    Write-Output "[INFO] CopyMode: $CopyMode"
    if ($Run) {
        Write-StatusLog -Path $runLog -Message "INFO Source: $Source"
        Write-StatusLog -Path $runLog -Message "INFO Destination: $Destination"
        Write-StatusLog -Path $runLog -Message "INFO CopyMode: $CopyMode"
    } else {
        Write-StatusLog -Path $simLog -Message "INFO Source: $Source"
        Write-StatusLog -Path $simLog -Message "INFO Destination: $Destination"
        Write-StatusLog -Path $simLog -Message "INFO CopyMode: $CopyMode"

        # シミュレーション実行（/L）。ファイル操作は行わずログを出力する
        Write-Output "[INFO] シミュレーション実行（/L）。ログ: $simLog"
        Write-StatusLog -Path $simLog -Message "INFO Simulation start (/L). Log: $simLog"
        $simOptions = @("/$CopyMode", '/L', '/NFL', '/NDL', "/MT:$SimThreads") + $ExtraOptions
        robocopy "$Source" "$destForRobo" @simOptions /LOG+:"$simLog"

        # 実行スイッチが付いていなければここで終了
        Write-Output "[INFO] シミュレーション完了。実コピーする場合は -Run を付けて実行してください。"
        Write-StatusLog -Path $simLog -Message 'INFO Simulation finished. Use -Run to execute copy.'
        Write-StatusLog -Path $simLog -Message 'SIMULATION OK'
        if ($mappedDrive) { Remove-PSDrive -Name $mappedDrive.TrimEnd(':') -Force }
        if ($logDrive) { Remove-PSDrive -Name $logDrive.TrimEnd(':') -Force }
        exit 0
    }

    # 実コピーの実行。/MIR でミラーリング、/Z 再開可能、/MT マルチスレッド、/R /W 再試行制御
    Write-Output "[INFO] 実行モード: コピー開始。ログ: $runLog"
    Write-StatusLog -Path $runLog -Message "INFO Run start. Log: $runLog"
    $runOptions = @("/$CopyMode", "/MT:$Threads", "/R:$Retries", "/W:$Wait") + $ExtraOptions
    if ($Restartable) { $runOptions += '/Z' }
    robocopy "$Source" "$destForRobo" @runOptions /LOG+:"$runLog"

    # robocopy の終了コードを取得して判定
    $code = $LASTEXITCODE
    if ($mappedDrive) { Remove-PSDrive -Name $mappedDrive.TrimEnd(':') -Force }

    # robocopy の終了コード仕様に基づき >=8 は重大エラー
    if ($code -ge 8) {
        Write-StatusLog -Path $runLog -Message "RUN FAILED (robocopy exit code $code)"
        Write-Error "[ERROR] robocopy エラーコード $code 。ログを確認してください: $runLog"
        if ($logDrive) { Remove-PSDrive -Name $logDrive.TrimEnd(':') -Force }
        exit $code
    } else {
        Write-StatusLog -Path $runLog -Message "RUN OK (robocopy exit code $code)"
        Write-Output "[OK] コピー完了 (exit code $code)。ログ: $runLog"
        if ($logDrive) { Remove-PSDrive -Name $logDrive.TrimEnd(':') -Force }
        exit 0
    }
}
catch {
    # 例外発生時はマッピング解除してエラーメッセージを出す
    if ($mappedDrive) { Remove-PSDrive -Name $mappedDrive.TrimEnd(':') -Force -ErrorAction SilentlyContinue }
    if ($logDrive) { Remove-PSDrive -Name $logDrive.TrimEnd(':') -Force -ErrorAction SilentlyContinue }
    $logTarget = if ($Run) { $runLog } else { $simLog }
    if ($logTarget) {
        Write-StatusLog -Path $logTarget -Message "EXCEPTION: $($_.Exception.Message)"
    } else {
        Write-Error "[LOG-FALLBACK] EXCEPTION: $($_.Exception.Message)"
    }
    Write-Error "[EXCEPTION] $_"
    exit 1
}

