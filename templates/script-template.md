# Script Page Template

以下をコピーして `_scripts/` 配下に新しい Markdown ファイルとして追加する。

```md
---
title: スクリプト名
summary: 何をするスクリプトかを1文で書く
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+
updated_at: 2026-03-16
published: false
tags:
  - tag1
  - tag2
---

## 概要

ここに目的を書く。

## カテゴリ

- 現時点では `PowerShell` か `いたずら用` のどちらかを使う

## 入力

- 何を受け取るか

## 出力

- 何が返るか

## 実行例

```powershell
Write-Output "example"
```

## 注意点

- 環境依存の条件
- 危険な操作があるかどうか

## 公開状態

- 公開するまでは `published: false` のままにする
- 公開対象に入れる時だけ `published: true` に変更する

## 補足

必要なら GitHub リンクや改変履歴を書く。
```
