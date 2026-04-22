---
title: BM25/TF-IDF/ハイブリッドのパラメータを自動チューニングするスクリプト
summary: BM25(k1/b)・TF-IDF(ngram_range)・ハイブリッド alpha のグリッドサーチを実行し、最適なパラメータ組み合わせを CSV で出力する。
language: Python
category: Python
environment: Python 3.10+ / scikit-learn / PyYAML
updated_at: 2026-04-21
published: true
tags:
  - python
  - rag
  - nlp
  - bm25
  - tuning
  - grid-search
---

## 概要

RAG の検索精度に影響するパラメータをグリッドサーチして最適な組み合わせを見つけるスクリプト。  
`eval_retrieval.py` で精度が伸び悩んだときに、手作業でパラメータを変えて試すのではなく、自動で総当たり検証できる。

探索するパラメータ:

| パラメータ | 対象 | 候補例 |
|---|---|---|
| BM25 `k1` | 単語頼度の飽和点 | 0.5, 0.8, 1.0, 1.2, 1.5, 2.0 |
| BM25 `b` | 文書長正規化の強さ | 0.3, 0.5, 0.65, 0.75, 0.85 |
| TF-IDF `ngram_range` | 文字 n-gram の長さ | (2,3), (2,4), (2,5), (3,5) |
| ハイブリッド `alpha` | TF-IDF と BM25 の混合比率 | 0.3, 0.4, 0.5, 0.6, 0.7, 0.8 |

依存: `scikit-learn`, `PyYAML`

## 基本的な使い方

```bash
python scripts/tune_retrieval.py \
  --chunks data/chunks.jsonl \
  --eval data/eval_tuning.csv
```

完了すると `eval_tuning_results.csv` に全組み合わせの精度が書き出され、ベスト設定がコンソールに表示される。

## 出力例

```
[Best] mode=hybrid alpha=0.70  BM25(k1=1.5,b=0.75)  TF-IDF(ngram=(2,4))
       P@1=0.900  MRR=0.950
Results saved to: eval_tuning_results.csv
```

`eval_tuning_results.csv` の列:
```
mode, ngram_range, bm25_k1, bm25_b, alpha, mean_P@1, mean_P@3, mean_MRR, mean_MAP, n
```

## 主なパラメータ

| パラメータ | デフォルト | 説明 |
|---|---|---|
| `--chunks` | `data/chunks.jsonl` | チャンク JSONL |
| `--eval` | — | チューニング用評価 CSV（必須） |

## チューニングの流れ

1. `rag_build_jsonl.py` でチャンクを作る
2. 評価データ（`eval_tuning.csv`）を手作業または半自動で作る
3. `tune_retrieval.py` でグリッドサーチする
4. ベスト設定を `eval_retrieval.py` の実行に反映する（設定値をコードまたは引数に指定）
5. `eval_sample.csv`（最終評価用データ）で最終確認する

## eval CSV の作り方（最小）

```csv
id,question,expected_source_path
Q001,ライセンスを更新する手順は？,data/chunk/license.md
Q002,製品Aをインストールする方法,data/chunk/setup-a.md
```

最低 10〜20 件ほどの「質問と正解ファイル」のペアがあれば動く。

## 注意点

- `eval_tuning.csv` はチューニング専用データとして扱い、最終精度評価には使わない。チューニング用データへの過適合を防ぐため、`eval_sample.csv`（別データ）で最終検証する
- 組み合わせ数は候補値に比例して増える。候補を増やすと時間がかかるため、まず粗いグリッドで絞ってから細かく探索するのが効率的
- BM25 はこのスクリプト内に内製実装されており、外部ライブラリは不要

## 使いどころ

- 新しい知識ベースを用意したあとに、デフォルト設定より精度を上げたい場合
- チャンクサイズや重複設定を変えたあとに、合わせてパラメータを再チューニングしたい場合
