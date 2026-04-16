---
title: エクスプローラーで拡張子と隠しファイルを表示する
summary: レジストリを変更してファイル拡張子と隠しファイル・フォルダの表示を有効化し、Explorer を再起動して反映する。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+ / Windows 10・11
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - explorer
  - registry
  - setup
---

## 概要

Windows のエクスプローラーで「拡張子の表示」と「隠しファイル・フォルダの表示」をレジストリ経由で有効化するスクリプト。設定変更後に Explorer を再起動して即時反映する。

## 簡易版（コピー＆ペーストで即実行）

```powershell
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# 拡張子を表示
Set-ItemProperty -Path $regPath -Name HideFileExt -Value 0 -Type DWord

# 隠しファイル・フォルダを表示
Set-ItemProperty -Path $regPath -Name Hidden -Value 1 -Type DWord

# Explorer を再起動して反映
Get-Process explorer -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 400
Start-Process explorer
```

## オプション: 保護されたOSファイルも表示

```powershell
Set-ItemProperty -Path $regPath -Name ShowSuperHidden -Value 1 -Type DWord
```

## 完全版スクリプト（パラメータ・エラーハンドリング付き）

以下のスクリプトを `show-extensions-hidden.ps1` として保存して使用する。

```powershell
<#
.SYNOPSIS
 Windows 11 でエクスプローラーの「拡張子の表示」と「隠しファイルの表示」を有効化するスクリプト。

.DESCRIPTION
 HKCU の Explorer\Advanced にある設定を変更します:
  - HideFileExt = 0  : 拡張子を表示
  - Hidden = 1       : 隠しファイル/フォルダーを表示
  - ShowSuperHidden  : (オプション) 保護されたOSファイルを表示 (1=表示, 0=非表示)
 変更後、Explorer を再起動して反映します。

.PARAMETER ShowProtected
 保護されたオペレーティングシステムファイルも表示する場合に指定します（ShowSuperHidden = 1）。

.PARAMETER NoRestart
 Explorer を再起動せずにレジストリだけ変更したい場合に指定します（手動で反映してください）。

.EXAMPLE
 .\show-extensions-hidden.ps1 -ShowProtected
#>

param(
    [switch]$ShowProtected,
    [switch]$NoRestart
)

$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

try {
    Write-Host "設定中: HideFileExt = 0 （拡張子を表示）"
    Set-ItemProperty -Path $regPath -Name HideFileExt -Value 0 -Type DWord -ErrorAction Stop

    Write-Host "設定中: Hidden = 1 （隠しファイル・フォルダーを表示）"
    Set-ItemProperty -Path $regPath -Name Hidden -Value 1 -Type DWord -ErrorAction Stop

    if ($ShowProtected) {
        Write-Host "設定中: ShowSuperHidden = 1 （保護されたOSファイルを表示）"
        Set-ItemProperty -Path $regPath -Name ShowSuperHidden -Value 1 -Type DWord -ErrorAction Stop
    } else {
        Write-Host "ShowSuperHidden は変更しません（保護されたOSファイルは非表示のまま）。"
    }

    if ($NoRestart) {
        Write-Host "NoRestart が指定されました。Explorer を再起動しません。手動で反映してください。"
        exit 0
    }

    Write-Host "Explorer を再起動して変更を反映します..."
    Get-Process explorer -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction Stop
        } catch {
            Write-Warning "Explorer の停止に失敗しました: $_"
        }
    }
    Start-Sleep -Milliseconds 400
    Start-Process explorer

    Write-Host "完了：エクスプローラーを再起動しました。"
}
catch {
    Write-Error "エラーが発生しました: $_"
    exit 1
}
```

### 完全版の使い方

```powershell
# 拡張子 + 隠しファイルを表示（Explorer 自動再起動）
.\show-extensions-hidden.ps1

# 保護されたOSファイルも含めて表示
.\show-extensions-hidden.ps1 -ShowProtected

# レジストリだけ変更（Explorer 再起動しない）
.\show-extensions-hidden.ps1 -NoRestart
```

## 設定値

| レジストリ名 | 値 | 意味 |
|---|---|---|
| HideFileExt | 0 | 拡張子を表示 |
| HideFileExt | 1 | 拡張子を非表示 |
| Hidden | 1 | 隠しファイルを表示 |
| Hidden | 2 | 隠しファイルを非表示 |
| ShowSuperHidden | 1 | 保護されたOSファイルを表示 |
| ShowSuperHidden | 0 | 保護されたOSファイルを非表示 |

## 注意点

- HKCU（現在のユーザー）のみ変更するため管理者権限は不要
- Explorer 再起動時にタスクバーが一瞬消えるが自動復帰する
- `ShowSuperHidden` を有効にすると OS のシステムファイルが見えるようになるため注意

## 使いどころ

- 新しい端末のセットアップ
- 拡張子が非表示で困るユーザーへの一括設定
