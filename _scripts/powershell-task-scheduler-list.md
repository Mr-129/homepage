---
title: タスクスケジューラの登録タスクを一覧表示する
summary: Get-ScheduledTask でタスク一覧を取得し、パス・名前・状態をテーブル表示する。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+ / Windows 10・11
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - task-scheduler
  - inventory
---

## 概要

Windows のタスクスケジューラに登録されたタスクを PowerShell で一覧表示する。フィルタ条件を変えて必要なタスクだけを抽出できる。

## 実行例

ルート直下で実行中のタスクを取得する例:

```powershell
Get-ScheduledTask |
  Where-Object { $_.TaskPath -eq '\' } |
  Where-Object { $_.State -like 'R*' } |
  Select-Object TaskPath, TaskName, State |
  Sort-Object TaskPath, TaskName |
  Format-Table -AutoSize
```

## フィルタのバリエーション

全タスクを表示:

```powershell
Get-ScheduledTask |
  Select-Object TaskPath, TaskName, State |
  Sort-Object TaskPath, TaskName |
  Format-Table -AutoSize
```

特定のタスク名で絞り込み:

```powershell
Get-ScheduledTask |
  Where-Object { $_.TaskName -like '*Backup*' } |
  Select-Object TaskPath, TaskName, State |
  Format-Table -AutoSize
```

## 注意点

- 一部のタスク情報の取得には管理者権限が必要
- タスク数が多い環境では出力量が大きくなる

## 使いどころ

- 端末に登録されたタスクの棚卸し
- 不要タスクの確認
- タスク実行状態の確認
