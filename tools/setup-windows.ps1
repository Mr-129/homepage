<#
Windows 用セットアップヘルパー (Jekyll / GitHub Pages)

使い方:
  管理者ではない通常モードで試して、必要なら管理者モードで再実行してください。
  PowerShell から次を実行します:
    powershell -ExecutionPolicy Bypass -File .\tools\setup-windows.ps1 -Serve

注意: このスクリプトは可能な限り自動化しますが、システムの変更（Ruby インストール等）はユーザーの承認と権限が必要です。
#>

param(
    [switch]$Serve
)

function CommandExists($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function PromptYesNo($message) {
    $ans = Read-Host "$message (y/n)"
    return $ans -match '^[Yy]'
}

Write-Host "=== Jekyll (GitHub Pages) Setup Helper ===`n"

# スクリプト位置 -> リポジトリルートへ移動
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot
Write-Host "Repository root: $RepoRoot`n"

# git
if (CommandExists git) {
    Write-Host "git: " (& git --version)
} else {
    Write-Warning "git が見つかりません。続行する前に Git をインストールしてください。"
}

# Ruby
if (CommandExists ruby) {
    Write-Host "Ruby: " (& ruby -v)
} else {
    Write-Warning "Ruby が見つかりません。"
    if (CommandExists winget) {
        if (PromptYesNo "winget が見つかりました。RubyInstaller + DevKit を winget でインストールしますか？") {
            Write-Host "winget で Ruby をインストールします。管理者権限が必要になる場合があります..."
            try {
                & winget install --id RubyInstallerTeam.RubyWithDevKit.3.2 --accept-package-agreements --accept-source-agreements --silent
            } catch {
                Write-Warning "winget インストールでエラーが発生しました。手動で https://rubyinstaller.org からインストールしてください。"
                exit 1
            }
            Write-Host "インストール完了後、PowerShell を再起動してからスクリプトを再実行してください。"
            exit 0
        } else {
            Write-Host "手動で RubyInstaller をインストールしてください: https://rubyinstaller.org"
            exit 1
        }
    } else {
        Write-Warning "winget が見つかりません。手動で Ruby をインストールしてください: https://rubyinstaller.org"
        exit 1
    }
}

# gem と bundler
if (CommandExists gem) {
    Write-Host "gem: " (& gem -v)
} else {
    Write-Warning "gem コマンドが見つかりません。Ruby の PATH を確認してください。"
}

if (CommandExists bundle) {
    Write-Host "bundle: " (& bundle -v)
} else {
    Write-Host "Bundler が見つかりません。インストールします..."
    & gem install bundler
    if ($LASTEXITCODE -ne 0) {
        Write-Error "gem install bundler に失敗しました。手動で実行してください: gem install bundler"
        exit 1
    }
}

# 依存関係をインストール
Write-Host "`n=> bundle install を実行します..."
try {
    & bundle install --jobs 4 --retry 3
} catch {
    Write-Error "bundle install に失敗しました。詳細はログを確認してください。"
    exit 1
}

# Jekyll ビルド
Write-Host "`n=> Jekyll をビルドします..."
try {
    & bundle exec jekyll build
} catch {
    Write-Error "jekyll build に失敗しました。"
    exit 1
}

Write-Host "`nビルド成功: 生成物は _site/ にあります。"

if ($Serve) {
    Write-Host "`n=> ローカルサーバーを起動します（http://127.0.0.1:4000/）..."
    & bundle exec jekyll serve --host 127.0.0.1
}

Write-Host "`n完了。必要なら .\tools\setup-windows.ps1 -Serve でサーバーを起動できます。"
