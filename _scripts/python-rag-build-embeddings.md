---
title: Ollama でチャンクの Embedding ベクトルを構築するスクリプト
summary: chunks.jsonl の各チャンクに対して Ollama の埋め込みモデルを呼び出し、ベクトルを embeddings.json に保存する。
language: Python
category: Python
environment: Python 3.10+ / httpx / Ollama（ローカル）
updated_at: 2026-04-21
published: true
tags:
  - python
  - rag
  - embedding
  - ollama
  - nlp
---

## 概要

`chunks.jsonl`（`rag_build_jsonl.py` の出力）を読み込み、Ollama の Embedding エンドポイント（`/api/embed`）でベクトル化して `embeddings.json` に保存する。  
保存済みのベクトルは `eval_retrieval.py` の `--embeddings` オプションで読み込み、TF-IDF / BM25 との精度比較ができる。

事前に Ollama が起動していて埋め込みモデルがプルされていることが必要。

```bash
ollama pull nomic-embed-text
```

依存: `httpx`（`pip install httpx`）

## 基本的な使い方

```bash
python scripts/build_embeddings.py
```

デフォルトで `data/chunks.jsonl` を読み、`data/embeddings.json` に出力する。

### パスとモデルを指定する場合

```bash
python scripts/build_embeddings.py \
  --chunks data/chunks.jsonl \
  --out data/embeddings.json \
  --model nomic-embed-text \
  --ollama-url http://localhost:11434
```

## 主なパラメータ

| パラメータ | デフォルト | 説明 |
|---|---|---|
| `--chunks` | `data/chunks.jsonl` | 入力チャンク JSONL |
| `--out` | `data/embeddings.json` | 出力ベクトル JSON |
| `--model` | `nomic-embed-text` | 使用する Ollama モデル名 |
| `--ollama-url` | `http://localhost:11434` | Ollama サーバーの URL |

## 出力フォーマット

```json
{
  "model": "nomic-embed-text",
  "count": 42,
  "embeddings": [
    {
      "chunk_id": "sha256:abcd1234...",
      "embedding": [0.012, -0.034, 0.091, ...]
    },
    ...
  ]
}
```

トップレベルは `model`・`count`・`embeddings` を持つ dict。  
`embeddings` 配下の各エントリが `chunk_id` とベクトル（float のリスト）のペア。  
`eval_retrieval.py` がこのファイルを読み込んでコサイン類似度検索を行う。

## 実行の流れ

1. `chunks.jsonl` を行ごとに読み込む
2. 各チャンクについて `title / topic / product / tags + text` を連結した検索テキストを作る
3. Ollama `/api/embed` エンドポイントに POST してベクトルを取得する
4. 進捗と経過時間をコンソールに出力しながら処理する
5. 全件完了後に `embeddings.json` へ書き出す

## 注意点

- Ollama がローカルで起動していない場合は接続エラーになる（`ollama serve` で起動）
- モデルが未プルの場合は `ollama pull <model>` が必要
- チャンク数が多い（数千件以上）と時間がかかる。ラップトップ CPU でも `nomic-embed-text` は数百件/分が目安
- ネットワーク越しの Ollama に向ける場合は `--ollama-url` でホストを変更する

## 使いどころ

- TF-IDF / BM25 で精度が頭打ちになったとき、意味ベースの類似度検索（埋め込み）を試したい場合
- `eval_retrieval.py` で `--modes embedding,hybrid3` を指定して TF-IDF との精度比較をする前処理
- Ollama を使うためクラウドへの送信なし。社内文書でも安全に使える

## Ollama モデルの参考

| モデル名 | 特徴 |
|---|---|
| `nomic-embed-text` | 軽量・高速。日本語もそれなりに対応 |
| `mxbai-embed-large` | 英語精度高め。サイズ大きめ |
| `bge-m3` | 多言語対応。日本語に強め |
