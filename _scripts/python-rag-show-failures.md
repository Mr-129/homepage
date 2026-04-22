---
title: RAG 評価の P@1 失敗問を一覧表示するスクリプト
summary: eval_retrieval.py の出力 CSV から特定モードの P@1 失敗問だけを抽出して表示する。精度デバッグ用。
language: Python
category: Python
environment: Python 3.10+
updated_at: 2026-04-21
published: true
tags:
  - python
  - rag
  - diagnostic
  - evaluation
---

## 概要

`eval_retrieval.py` が出力した `eval_results.csv` を読み込み、指定したモードの **P@1 が 0（失敗）だった問い**だけを抽出して表示する。  
「どの質問が外れているか」を素早く確認してチャンクや eval データの改善に役立てる。

依存なし（標準ライブラリのみ）。

## 事前準備

`eval_results.csv` が存在しない場合は先に `eval_retrieval.py` を実行する。

```bash
python scripts/eval_retrieval.py \
  --chunks data/chunks.jsonl \
  --eval data/eval_tuning.csv
```

## 基本的な使い方

```bash
python scripts/show_failures.py
# デフォルト: hybrid3 モードの失敗問を表示

python scripts/show_failures.py tfidf
# モードを指定する場合
```

## 出力例

```
hybrid3 P@1 failures: 3/40

  Q005: 製品Aのライセンスが切れた場合の対処は？
  Q018: バックアップからリストアする手順
  Q031: 障害発生時の連絡フロー
```

失敗した問いの ID とクエリ文字列（60文字まで）が一覧表示される。

## 確認できるモード

`eval_results.csv` に含まれているモード名であれば指定できる。  
利用可能なモード一覧は、`eval_results.csv` の `mode` 列を確認する。

```bash
# mode 列のユニーク値をざっくり確認する例
python -c "import csv; rows=list(csv.DictReader(open('eval_results.csv'))); print(set(r['mode'] for r in rows))"
```

## 失敗問から原因を探るフロー

```
show_failures.py で失敗問を確認
          ↓
失敗問のクエリ文字列でチャンクを手動検索（rag_retrieve.py）
          ↓
A: 正解チャンクが存在しない  → Markdown を追加して rag_build_jsonl.py を再実行
B: 正解チャンクはあるが hit しない → チャンクの title/tags を充実させる
C: eval CSV の expected_source_path がズレている → check_source_match.py で確認
```

## 注意点

- `eval_results.csv` はプロジェクトルートを作業ディレクトリにして実行したときに生成される。別ディレクトリから呼ぶとファイルが見つからないエラーになる
- `show_failures.py` はあくまで「どの問いが外れたか」を見るためのスクリプト。原因の特定は `rag_retrieve.py` と `check_quality.py` を合わせて使う

## 使いどころ

- `eval_retrieval.py` で精度を確認したあと、具体的にどの問いが弱いかを把握したいとき
- チャンクを追加・修正したあとに「改善前後で失敗問が変わったか」を比較するとき
