---
title: 自動起動サービスの一覧を取得する
summary: 自動起動に設定されたサービスの名前・表示名・状態を一覧表示し、起動時の問題調査に使う。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - service
  - inventory
  - troubleshooting
---

## 概要

`Win32_Service` から自動起動（`StartMode='Auto'`）のサービスを一覧取得する。起動時に問題が発生した場合の調査に使う。

## 実行例

```powershell
Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto'" |
  Select-Object Name, DisplayName, StartMode, State, StartName |
  Format-Table -AutoSize
```

## フィルタのバリエーション

停止しているのに自動起動設定のサービスだけ表示:

```powershell
Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto'" |
  Where-Object { $_.State -ne 'Running' } |
  Select-Object Name, DisplayName, State, StartName |
  Format-Table -AutoSize
```

## 注意点

- サービス数が多い環境では出力量が大きくなる
- `StartName` にはサービスの実行アカウントが表示される

## 使いどころ

- PC 起動が遅い場合の原因調査
- 不要なサービスの特定
- サービスの起動状態の棚卸し
