---
title: Windows セキュリティ設定を PowerShell で変更・確認する
summary: SMB1.0 有効化、安全でないゲストログオン許可、デジタル署名無効化など、Windows セキュリティ設定を一括管理するスクリプト群。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+ / 管理者権限必須 / Windows 10・11
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - security
  - registry
  - smb
  - admin-required
---

## 概要

Windows のセキュリティ関連設定（SMB1.0、ゲストログオン、デジタル署名）を PowerShell で変更・確認するためのスクリプト群。BAT ランチャーから管理者起動できる構成になっている。

## 構成

```
SettingsChangeScripts/
├── settings/          # 実行用スクリプト
│   ├── CommonFunctions.ps1
│   ├── SMB1.0_Enable.ps1
│   ├── SaftyGuestLogonEnable.ps1
│   ├── AlwaysDigitalStampChange.ps1
│   └── RegistryPathBackup.ps1
├── test/              # 確認用スクリプト
│   ├── SMB_Settings.ps1
│   ├── NotSaftyGuestLogon.ps1
│   └── AlwaysDigitalStamp.ps1
└── bat/               # ランチャー
    └── setup.bat
```

## 共通関数（CommonFunctions.ps1）

管理者判定、レジストリ DWORD の目標値設定、結果オブジェクト生成を共通化。

```powershell
# 管理者権限の判定
function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# レジストリ DWORD を目標値に合わせる（同値なら変更しない）
function Ensure-RegistryDwordValue {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    $before = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($before -eq $Value) {
        return [PSCustomObject]@{ Changed = $false; BeforeValue = $before }
    }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
    return [PSCustomObject]@{ Changed = $true; BeforeValue = $before; AfterValue = $Value }
}
```

## 設定変更スクリプト

### SMB1.0 有効化

SMB1Protocol / Client / Server を有効化し、自動削除（Deprecation）を無効化する。

```powershell
# SMB1 本体を有効化
Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart

# クライアント / サーバーも有効化
Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Client" -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Server" -NoRestart

# 自動削除を無効化
Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Deprecation" -NoRestart
```

### 安全でないゲストログオン有効化

ポリシーレジストリキーに直接値を設定する。`gpupdate` は実行しない（GPO 未構成時に値がクリアされるのを防止）。

```powershell
$path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
Ensure-RegistryDwordValue -Path $path -Name "AllowInsecureGuestAuth" -Value 1
```

### デジタル署名の無効化

`secedit` を使用してローカルセキュリティポリシー経由で変更する。レジストリ直接書き込みでは gpedit.msc に反映されないため。

## 確認スクリプト

BAT ランチャーが結果を判定できるよう、OK 時は終了コード `0`、NG 時は `1` を返す。

```powershell
# SMB1 の有効化状態を確認する例
$state = (Get-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Client").State
if ($state -eq "Enabled") {
    Write-Host "SMB1クライアント有効化 : OK"
    exit 0
} else {
    Write-Host "SMB1クライアント有効化 : NG"
    exit 1
}
```

## 注意点

- **SMB1 有効化やデジタル署名の無効化はセキュリティリスクを伴う**。対象端末を限定し、実施理由を記録すること
- ドメイン参加端末ではドメイン GPO で上書きされる可能性がある
- `.ps1` ファイルは **UTF-8 BOM** で保存する
- 変更前にレジストリのバックアップを取得することを推奨

## 使いどころ

- レガシー機器との接続のために SMB1 を一時的に有効化する
- NAS 接続のためにゲストログオンを許可する
- 古いファイルサーバーとの互換性のためにデジタル署名設定を調整する

## スクリプトのダウンロード

<div class="download-wrap">
<a href="{{ site.baseurl }}/assets/downloads/windows-security-settings.zip" download class="download-button"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
windows-security-settings.zip をダウンロード</a>
</div>

ZIP には以下のファイルが含まれています:

| フォルダ | ファイル | 内容 |
|---|---|---|
| `settings/` | `CommonFunctions.ps1` | 共通関数（管理者判定、レジストリ操作） |
| `settings/` | `SMB1.0_Enable.ps1` | SMB1.0 有効化 |
| `settings/` | `SaftyGuestLogonEnable.ps1` | 安全でないゲストログオン有効化 |
| `settings/` | `AlwaysDigitalStampChange.ps1` | デジタル署名の無効化（secedit 経由） |
| `settings/` | `RegistryPathBackup.ps1` | レジストリのバックアップ |
| `test/` | `SMB_Settings.ps1` | SMB1 有効化状態の確認 |
| `test/` | `NotSaftyGuestLogon.ps1` | ゲストログオン設定の確認 |
| `test/` | `AlwaysDigitalStamp.ps1` | デジタル署名設定の確認 |
| `bat/` | `setup.bat` | 管理者権限で起動するランチャー |
| `bat/` | `setup-launcher.ps1` | BAT から呼ばれる起動制御スクリプト |
