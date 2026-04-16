---
title: PowerShell でファイル・フォルダを探索する
summary: ファイル名検索、正規表現フィルタ、結果のファイル出力、フォルダ名検索など、探索系コマンドのパターン集。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - file-system
  - search
---

## 概要

`Get-ChildItem` を使ったファイル・フォルダ探索のパターンをまとめたもの。名前の完全一致、正規表現、結果出力、フォルダ検索の4パターンを記録する。

## パターン1: ファイル名の完全一致検索

```powershell
Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -eq 'example.txt' } |
  Select-Object -ExpandProperty FullName
```

## パターン2: 正規表現でフィルタ

複数の拡張子をまとめて検索する場合。

```powershell
Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match '\.(log|txt)$' } |
  Select-Object -ExpandProperty FullName
```

## パターン3: 検索結果をファイルに出力

```powershell
Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match '\.sln$' } |
  Select-Object -ExpandProperty FullName |
  Out-File -FilePath .\results.txt -Encoding utf8
```

## パターン4: フォルダ名で検索

特定の名前のフォルダを再帰的に探す。

```powershell
Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -eq '対象フォルダ名' } |
  ForEach-Object { $_.FullName }
```

## 注意点

- `-ErrorAction SilentlyContinue` を付けないと、アクセス権のないフォルダでエラーが大量に出る
- ネットワークドライブでは実行時間が長くなる
- 大量のファイルがある場合は `-Filter` パラメータを使うほうが高速

## 使いどころ

- プロジェクト内の特定ファイル探し
- ソリューションファイル（.sln）やログの一括検索
- フォルダ構成の確認
