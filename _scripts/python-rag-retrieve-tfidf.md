---
title: TF-IDF による RAG 検索スクリプト（最小実装）
summary: LLM・APIキー不要。TF-IDF + コサイン類似度で Markdown/TXT チャンクを検索する最小 RAG 実装。
language: Python
category: Python
environment: Python 3.10+ / scikit-learn / PyYAML
updated_at: 2026-04-21
published: true
tags:
  - python
  - rag
  - nlp
  - tfidf
  - search
---

## 概要

`data/chunk/` 配下の `.md` / `.txt` ファイルを読み込み、TF-IDF（文字 n-gram）+ コサイン類似度でクエリに近いチャンクを返す。  
LLM を呼ばないため API キー不要。**「検索が効くかを最初に確認する」** ための動作検証スクリプト。

> 本番用の JSONL 入力版検索・精度評価は `eval_retrieval.py` を参照。

依存: `scikit-learn`, `PyYAML`

```bash
pip install scikit-learn pyyaml
```

## 基本的な使い方

### 1 回だけ検索する

```bash
python scripts/rag_retrieve.py --query "ライセンス更新の手順"
```

### 対話モード（複数クエリを試す）

```bash
python scripts/rag_retrieve.py
# > プロンプトが出るので何度でも入力できる。空行で終了。
```

### パスと件数を指定する

```bash
python scripts/rag_retrieve.py \
  --data-dir data/chunk \
  --query "ライセンス更新" \
  --top-k 5
```

## 主なパラメータ

| パラメータ | デフォルト | 説明 |
|---|---|---|
| `--data-dir` | `data/chunk` | チャンクファイルのフォルダ |
| `--query` | なし（対話モード） | 検索クエリ文字列 |
| `--top-k` | `3` | 返す件数 |

## 出力例

```
Query: ライセンス更新の手順
Chunks: 42  TopK: 3
-
[1] score=0.6134  title=ライセンス更新手順
    source_path=data/chunk/license.md
    preview=ライセンスの更新は毎年4月に実施します。管理者ポータルからアカウントを...
-
[2] score=0.4021  title=製品Aセットアップ
    ...
```

## 検索ロジック

1. `data/chunk/` の `.md` / `.txt` をすべて読み込む（1ファイル = 1チャンク扱い）
2. 本文に `title` / `tags` / `product` / `topic` のメタデータを混ぜた検索テキストを作る
3. TF-IDF ベクトライザー（文字 2〜4-gram）で全チャンクをベクトル化
4. クエリも同じ変換をかけてコサイン類似度を計算し、上位 K 件を返す

### 文字 n-gram を使う理由

日本語は形態素解析なしでは単語境界が不明なため、文字の連続部分列（n-gram）で「ライセ」「イセン」「センス」のようなピースで一致を拾う。  
短い単語でもカタカナ・漢字が混ざっていればある程度ヒットする。

## 注意点

- このスクリプトは **1ファイル = 1チャンク** で扱う。同じファイルから見出し単位で分割したい場合は `rag_build_jsonl.py` → `eval_retrieval.py` の組み合わせを使う
- LLM は呼ばないため、検索結果をそのまま回答として使うことはできない。「どのチャンクがヒットするか」を確認する用途
- TF-IDF は語彙の意味を理解しないため、「コスト」と「費用」のような同義語はヒットしないことがある。その場合は `build_embeddings.py` の埋め込み検索を試す

## 使いどころ

- 新しい知識ベース（Markdown ファイル群）を用意したときに、まず検索が効くかを素早く確認する
- API キーや GPU が不要なため、オフライン環境や検証環境での動作確認に向いている
- 埋め込みモデルを使う前の「ベースライン」として精度比較に使う
