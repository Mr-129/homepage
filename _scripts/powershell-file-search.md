---
title: PowerShell で拡張子別のファイル数を集計する
summary: ディレクトリ配下のファイルを拡張子ごとに数え、整理対象を把握するための例
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+
updated_at: 2026-03-16
published: true
tags:
  - powershell
  - inventory
  - file-system
---
## 概要

フォルダ内のファイルを拡張子ごとに集計し、どの種類のファイルが多いかを確認するためのスクリプトです。

## 実行例

```powershell
Get-ChildItem -Path . -File -Recurse |
  Group-Object Extension |
  Sort-Object Count -Descending |
  Select-Object Name, Count
```

## 注意点

- ファイル数が多いディレクトリでは時間がかかる場合があります。
- ネットワークドライブでは実行時間が長くなることがあります。

## 使いどころ

- 退避前の棚卸し
- ディレクトリ構成の見直し
- 移行対象の把握
