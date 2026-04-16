---
title: Microsoft Edge のインストールパスとバージョンを確認する
summary: Edge の実行ファイルが存在するかを確認し、バージョンを取得するワンライナー。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+ / Windows 10・11
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - edge
  - inventory
---

## 概要

Microsoft Edge は 32bit / 64bit でインストール先が異なる。どちらに入っているかを確認し、バージョンを取得するスクリプト。

## 実行例

```powershell
$p1 = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$p2 = 'C:\Program Files\Microsoft\Edge\Application\msedge.exe'

Write-Output ("32bit path exists=" + (Test-Path $p1))
Write-Output ("64bit path exists=" + (Test-Path $p2))

if (Test-Path $p1) { & $p1 --version | Write-Output }
if (Test-Path $p2) { & $p2 --version | Write-Output }
```

## 注意点

- `--version` オプションで Edge のウィンドウは開かずバージョン文字列だけ返る
- Chromium ベースの Edge が前提（レガシー Edge では使えない）

## 使いどころ

- 端末の Edge バージョン棚卸し
- Edge のパスをスクリプトで参照する前の確認
