---
title: robocopy でフォルダをミラーリングするバックアップスクリプト
summary: robocopy を使ってフォルダのミラーリングを行うスクリプト。シミュレーション・本番切替、ログ管理、ネットワーク共有対応。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+ / robocopy
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - backup
  - robocopy
  - file-system
---

## 概要

`robocopy` を PowerShell から呼び出してフォルダのミラーリングを行うスクリプト。シミュレーションモードで安全に確認してから本番実行に切り替えられる。ネットワーク共有（UNC パス）への資格情報付きアクセスにも対応。

## 基本的な使い方

### シミュレーション（実ファイル操作なし）

`-Run` を付けないとシミュレーションになる。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\copy.ps1 `
  -Source "C:\Backup\Source" `
  -Destination "\\server\share\backup" `
  -LogDir "C:\Backup\Logs"
```

### 本番実行

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\copy.ps1 `
  -Run `
  -Source "C:\Backup\Source" `
  -Destination "\\server\share\backup" `
  -LogDir "C:\Backup\Logs" `
  -CopyMode MIR
```

## 主なパラメータ

| パラメータ | 説明 |
|---|---|
| `-Source` | コピー元フォルダ |
| `-Destination` | コピー先（UNC パス可） |
| `-LogDir` | ログ保存先 |
| `-Run` | 指定すると本番実行 |
| `-CopyMode` | `MIR`（ミラー）/ `E`（サブフォルダ含む）/ `S`（空フォルダ除外） |
| `-Credential` | コピー先への資格情報 |
| `-Threads` | robocopy のスレッド数（`/MT`） |

## ログ

ログは月フォルダ（YYYYMM）配下に日別で保存される。

- シミュレーション: `YYYYMM/backup_sim_YYYYMMDD.log`
- 本番: `YYYYMM/backup_copy_YYYYMMDD.log`

## 注意点

- **`/MIR` はコピー先からファイルを削除する**。パス指定ミスはデータ消失に直結する
- `-LogDir` はコピー元と同じフォルダに置かない（ミラー対象に含まれるため）
- `.ps1` ファイルは **UTF-8 BOM** で保存する（Windows PowerShell 5.1 の文字コード問題対策）
- タスクスケジューラで自動実行する場合は、共有へ書き込み可能なユーザーで登録する

## タスクスケジューラ登録時の設定例

| 項目 | 値 |
|---|---|
| プログラム | `powershell.exe` |
| 引数 | `-NoProfile -ExecutionPolicy Bypass -File "C:\path\to\script.ps1" -Run` |
| 開始 | スクリプト格納フォルダ |
| 実行ユーザー | 共有への書き込み権限があるユーザー |

## 使いどころ

- DB バックアップファイルの NAS への定期ミラーリング
- フォルダ単位のバックアップ自動化
- ネットワーク共有へのファイル同期

## スクリプトのダウンロード

<div class="download-wrap">
<a href="{{ site.baseurl }}/assets/downloads/robocopy-backup.ps1" download class="download-button"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
robocopy-backup.ps1 をダウンロード</a>
</div>

ダウンロード後、パラメータのデフォルト値（`$Source`, `$Destination`）を自分の環境に合わせて変更してから使用してください。

<details markdown="1">
<summary>スクリプト全文を表示（クリックで展開）</summary>

```powershell
{% raw %}
<#
PowerShell バックアップスクリプト

Usage:
    - シミュレーション（実際のファイル操作は行わない）
            powershell -ExecutionPolicy Bypass -File ".\copy.ps1"

    - 本番実行（コピーを行う）
            powershell -ExecutionPolicy Bypass -File ".\copy.ps1" -Run

    - 資格情報を使って実行する場合
            $cred = Get-Credential
            & ".\copy.ps1" -Run -Credential $cred

    - ログ保存先や robocopy オプションを指定する例:
            & ".\copy.ps1" -Run -LogDir 'C:\Logs' -CopyMode E -Threads 8 -ExtraOptions @('/XO','/FFT')

Notes:
    - デフォルトではミラーリング（/MIR）です。必要に応じて -CopyMode を変更してください。
    - 実行前に -Source / -Destination を確認してください。誤指定による削除リスクがあります。
#>

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

function Get-FreeDriveLetter {
    $used = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name
    $letters = 'Z','Y','X','W','V','U','T','S','R','Q','P','O','N','M','L','K','J','I','H','G','F','E','D'
    foreach ($l in $letters) { if ($used -notcontains $l) { return "$($l):" } }
    throw '空いているドライブ文字が見つかりません。'
}

$logDrive = $null
$logDirResolved = $LogDir
$simLog = $null
$runLog = $null

function Write-StatusLog {
    param([string]$Path, [string]$Message)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try {
        Add-Content -LiteralPath $Path -Value "[$ts] $Message" -ErrorAction Stop
    } catch {
        Write-Error "[LOG-FALLBACK] $Message (log write failed: $($_.Exception.Message))"
    }
}

if ([string]::IsNullOrWhiteSpace($Source)) { throw 'Source が空です。' }
if ([string]::IsNullOrWhiteSpace($Destination)) { throw 'Destination が空です。' }
if (-not (Test-Path -LiteralPath $Source)) { throw "Source が存在しません: $Source" }

$sourceItem = Get-Item -LiteralPath $Source -ErrorAction Stop
if (-not $sourceItem.PSIsContainer) { throw "Source がフォルダではありません: $Source" }
if (($Source.TrimEnd('\')) -ieq ($Destination.TrimEnd('\'))) { throw 'Source と Destination が同一です。' }
if (-not $Credential) {
    if (-not (Test-Path -LiteralPath $Destination)) {
        throw "Destination が存在しません: $Destination"
    }
}

$mappedDrive = $null
try {
    if ($LogCredential -and ($LogDir -like '\\*')) {
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
        $drive = Get-FreeDriveLetter
        New-PSDrive -Name $drive.TrimEnd(':') -PSProvider FileSystem -Root $Destination -Credential $Credential -ErrorAction Stop | Out-Null
        $mappedDrive = $drive
        $destForRobo = "$mappedDrive\\"
    } else {
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

        Write-Output "[INFO] シミュレーション実行（/L）。ログ: $simLog"
        Write-StatusLog -Path $simLog -Message "INFO Simulation start (/L). Log: $simLog"
        $simOptions = @("/$CopyMode", '/L', '/NFL', '/NDL', "/MT:$SimThreads") + $ExtraOptions
        robocopy "$Source" "$destForRobo" @simOptions /LOG+:"$simLog"

        Write-Output "[INFO] シミュレーション完了。実コピーする場合は -Run を付けて実行してください。"
        Write-StatusLog -Path $simLog -Message 'INFO Simulation finished. Use -Run to execute copy.'
        Write-StatusLog -Path $simLog -Message 'SIMULATION OK'
        if ($mappedDrive) { Remove-PSDrive -Name $mappedDrive.TrimEnd(':') -Force }
        if ($logDrive) { Remove-PSDrive -Name $logDrive.TrimEnd(':') -Force }
        exit 0
    }

    Write-Output "[INFO] 実行モード: コピー開始。ログ: $runLog"
    Write-StatusLog -Path $runLog -Message "INFO Run start. Log: $runLog"
    $runOptions = @("/$CopyMode", "/MT:$Threads", "/R:$Retries", "/W:$Wait") + $ExtraOptions
    if ($Restartable) { $runOptions += '/Z' }
    robocopy "$Source" "$destForRobo" @runOptions /LOG+:"$runLog"

    $code = $LASTEXITCODE
    if ($mappedDrive) { Remove-PSDrive -Name $mappedDrive.TrimEnd(':') -Force }

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
{% endraw %}
```

</details>
