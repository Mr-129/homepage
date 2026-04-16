---
title: PowerShell の実行ポリシーを変更する
summary: Set-ExecutionPolicy で実行ポリシーを RemoteSigned に変更し、スクリプト実行を許可する手順。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - security
  - setup
---

## 概要

PowerShell スクリプト（.ps1）を実行するには、実行ポリシーが `Restricted` 以外に設定されている必要がある。`RemoteSigned` に変更することで、ローカルスクリプトの実行を許可する。

## 実行例

現在のユーザーにだけ適用する場合:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

## 確認

```powershell
Get-ExecutionPolicy -List
```

## 注意点

- `-Scope CurrentUser` にすれば管理者権限は不要
- `-Scope LocalMachine` に設定する場合は管理者権限が必要
- `Bypass` はすべてのスクリプトを無制限に実行するため、常用は非推奨
- 企業環境ではグループポリシーで上書きされている場合がある

## 使いどころ

- PowerShell スクリプトを初めて実行する端末のセットアップ
- 開発環境の初期設定
