---
title: RAG 検索精度を P@1/MRR で評価するスクリプト
summary: TF-IDF・BM25・ハイブリッド・Embedding の各モードを一括評価し、P@1/MRR を CSV 出力する。
language: Python
category: Python
environment: Python 3.10+ / scikit-learn / numpy / PyYAML
updated_at: 2026-04-21
published: true
tags:
  - python
  - rag
  - nlp
  - evaluation
  - bm25
  - embedding
---

## 概要

RAG の「検索部分」だけを複数のアルゴリズムで評価する。  
正解チャンクIDを記録した eval CSV と `chunks.jsonl` を与えると、モードごとに **P@1** と **MRR** を計算して CSV 出力する。

| 評価指標 | 意味 |
|---|---|
| P@1 | 1件目が正解だった割合 |
| MRR | 正解の順位の逆数の平均（高いほど正解が上位に来やすい） |

依存: `scikit-learn`, `numpy`, `PyYAML`

```bash
pip install scikit-learn numpy pyyaml
```

## 基本的な使い方

```bash
python scripts/eval_retrieval.py \
  --chunks data/chunks.jsonl \
  --eval data/eval_sample.csv
```

### 埋め込みモードを含めて評価する場合

`build_embeddings.py` で `embeddings.json` を作ってから実行する。

```bash
python scripts/eval_retrieval.py \
  --chunks data/chunks.jsonl \
  --eval data/eval_tuning.csv \
  --modes embedding,hybrid3 \
  --embeddings data/embeddings.json
```

## 主なパラメータ

| パラメータ | デフォルト | 説明 |
|---|---|---|
| `--chunks` | `data/chunks.jsonl` | チャンク JSONL |
| `--eval` | — | 評価用 CSV（必須） |
| `--modes` | `tfidf,bm25,hybrid` | 評価するモード（カンマ区切り） |
| `--embeddings` | `data/embeddings.json` | 埋め込みベクトル JSON（`embedding` / `hybrid3` 使用時） |
| `--top-k` | `10` | 検索結果の上位 K 件を使って評価 |

## 評価 CSV の形式

```csv
id,question,expected_source_path
Q001,ライセンスを更新する手順は？,data/chunk/license.md
Q002,製品Aの設定方法,data/chunk/setup.md
```

- `expected_source_path` か `correct_chunk_ids`（SHA-256 ID）のどちらかで正解を指定できる
- `|` 区切りで複数の正解を指定可能（例: `data/chunk/a.md|data/chunk/b.md`）

## 評価モード一覧

| モード名 | アルゴリズム |
|---|---|
| `tfidf` | TF-IDF（文字 2〜3-gram + コサイン類似度） |
| `bm25` | BM25（k1/b パラメータ付き） |
| `hybrid` | TF-IDF + BM25 の加重平均 |
| `hybrid3` | TF-IDF + BM25 + Embedding の加重平均 |
| `embedding` | 埋め込みベクトルのコサイン類似度のみ |

`hybrid3` は TF-IDF / BM25 / Embedding を組み合わせるため `--embeddings` が必要。デフォルトのモード（`hybrid`）には指定不要。

## 出力

コンソールにモードごとのサマリーが出力される。

```
mode=tfidf      P@1=0.750  MRR=0.833
mode=bm25       P@1=0.800  MRR=0.867
mode=hybrid3    P@1=0.925  MRR=0.963
```

また `eval_results.csv` にもフル結果が出力され、`show_failures.py` で失敗問を確認できる。

## 注意点

- `eval_tuning.csv` は「精度チューニング用」、`eval_sample.csv` は「最終評価用」として分けて使うことを推奨する（チューニング用データで過学習しないように）
- `embedding` / `hybrid3` を使う場合は先に `build_embeddings.py` を実行しておく必要がある
- BM25 の実装はこのスクリプトに内製されており外部ライブラリ（rank-bm25 等）に依存しない

## 使いどころ

- 知識ベースの Markdown を整備したあとに「どのアルゴリズムが一番精度が出るか」を比較するとき
- チャンク分割サイズや重複設定を変えたあとに精度への影響を確認するとき
- 精度改善の都度、定量的な数値を記録しておく用途に
