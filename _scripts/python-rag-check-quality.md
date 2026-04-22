---
title: RAG チャンクのメタデータ品質チェック / ソースパス一致確認スクリプト
summary: chunks.jsonl のメタデータ不備（tags空・title無・パス異常）を検出し、eval CSV との source_path 不一致も確認する2本のスクリプト。
language: Python
category: Python
environment: Python 3.10+
updated_at: 2026-04-21
published: true
tags:
  - python
  - rag
  - diagnostic
  - quality
---

## 概要

RAG の精度が期待通りに出ないとき、まず「チャンクデータ自体がおかしくないか」を確認するための診断スクリプト2本。

| スクリプト | 主な用途 |
|---|---|
| `check_quality.py` | メタデータの不備（タグ無し・タイトル無し・パス異常）を検出 |
| `check_source_match.py` | eval CSV の正解 `source_path` が `chunks.jsonl` に存在するか照合 |

依存なし（標準ライブラリのみ）。

---

## check_quality.py

### 使い方

```bash
python scripts/check_quality.py
# デフォルト: data/chunks.jsonl を読む

python scripts/check_quality.py data/my_chunks.jsonl
# パスを明示する場合
```

### 出力例

```
Total chunks: 87
Issues found: 3
  [tags empty]  data/chunk/readme.md  chunk=sha256:abc123
  [no title]    data/chunk/old.md     chunk=sha256:def456
  [bad path]    data/chunk/.md        chunk=sha256:789abc

Unique source_paths (24):
  data/chunk/faq.md
  data/chunk/install.md
  ...
```

### チェック内容

| 問題 | 説明 |
|---|---|
| `[tags empty]` | `tags` フィールドが空またはリストが空 |
| `[no title]` | `title` フィールドが空 |
| `[bad path]` | `source_path` が `.md` だけになっているなどのパス異常 |

tags や title が空だと TF-IDF / BM25 の検索テキストが薄くなり、精度が下がりやすい。

---

## check_source_match.py

### 使い方

```bash
python scripts/check_source_match.py
# data/chunks.jsonl と data/eval_tuning.csv を固定パスで読む
```

### 出力例

```
=== eval expected_source_path NOT in chunks ===
  data/chunk/old_manual.md
    affected: ['Q003', 'Q007']

=== chunk source_paths (24) ===
  data/chunk/faq.md
  ...

=== Summary ===
  Eval unique sources: 15
  Chunk unique sources: 24
  Missing in chunks: 1
```

### 何を確認しているか

eval CSV に書いた正解 `expected_source_path` が、実際に `chunks.jsonl` に存在しない場合、その問いは**常に不正解扱い**になる。  
`eval_retrieval.py` を実行してもスコアが低いままなら、まずこのスクリプトでパスの不一致を確認する。

---

## よくある原因と対処

| 症状 | 確認スクリプト | 対処 |
|---|---|---|
| tags 空が多い | `check_quality.py` | front matter に `tags:` を追加して `rag_build_jsonl.py` を再実行 |
| 特定の問いが常に P@1=0 | `check_source_match.py` | eval CSV の `expected_source_path` を `chunks.jsonl` の実際のパスに合わせる |
| source_path が `data/chunk/.md` になっている | `check_quality.py` | ファイル名が空の `.md` が混入している。ファイル名を確認して再整備する |

## 使いどころ

- `rag_build_jsonl.py` を実行したあとの品質確認として毎回実行する習慣をつけると、精度デバッグの無駄が減る
- 評価スコアが予想より低いときのトラブルシュート最初の一手として
