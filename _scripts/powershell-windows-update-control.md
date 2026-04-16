---
title: Windows Update の自動ダウンロードを通知のみに変更する
summary: レジストリの AUOptions を変更して、Windows Update の自動ダウンロードを停止し通知だけにするスクリプト。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+ / 管理者権限必須
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - windows-update
  - registry
  - admin-required
---

## 概要

Windows Update の自動ダウンロードを無効化し、「ダウンロード前に通知する」設定に変更するスクリプト。レジストリの `AUOptions` を変更し、グループポリシーを更新する。

## 実行例

管理者権限の PowerShell で実行する。

```powershell
# 管理者確認
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Error "管理者として実行してください。"
    exit 1
}

$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

# キー作成
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# AUOptions: 2 = ダウンロード前に通知, 3 = 自動ダウンロード
Set-ItemProperty -Path $regPath -Name "AUOptions" -Value 2 -Type DWord

# 自動再起動を抑止（任意）
Set-ItemProperty -Path $regPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord

# ポリシー反映
gpupdate /force | Out-Null

# Windows Update サービス再起動
Stop-Service -Name wuauserv -ErrorAction SilentlyContinue
Start-Service -Name wuauserv -ErrorAction SilentlyContinue
```

## AUOptions の値

| 値 | 動作 |
|---|---|
| 2 | ダウンロード前に通知 |
| 3 | 自動ダウンロードしてインストール前に通知 |
| 4 | 自動ダウンロードして自動インストール |
| 5 | ローカル管理者が設定を選択可能 |

## 事前確認

レジストリパスの存在確認:

```powershell
Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
```

現在の設定値確認:

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
```

## 注意点

- 管理者権限が必須
- ドメイン参加端末ではグループポリシーで上書きされる可能性がある
- Windows Update を完全に停止するものではなく、通知に切り替えるだけ
- セキュリティ更新が適用されなくなるリスクがあるため、運用ルールを決めて使う

## 使いどころ

- 検証環境で意図しない Windows Update を防ぎたい場合
- 再起動タイミングを手動で制御したい場合
