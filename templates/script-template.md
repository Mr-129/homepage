# Script Page Template

以下をコピーして `_scripts/` 配下に新しい Markdown ファイルとして追加する。

分類運用の例:

- `_scripts/powershell/system/xxx.md`
- `_scripts/powershell/network/xxx.md`
- `_scripts/python/rag/xxx.md`

`_config.yml` の `scripts.permalink` が `/:path/` になっている場合、サブフォルダ構成はURLにも反映される。

```md
---
title: スクリプト名
summary: 何をするスクリプトかを1文で書く
shelf: Windows 運用
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

## 本棚

- `shelf` は表示上の大きな分類に使う
- 例: `Windows 運用`, `ファイル整理`, `RAG 開発`
- `shelf` を省略した場合は、当面 `category` が棚名として使われる

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
