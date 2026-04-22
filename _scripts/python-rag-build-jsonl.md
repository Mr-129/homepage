---
title: Markdown/TXT をRAG用 JSONL に変換するスクリプト
summary: Markdown の YAML front matter とH1～H6見出し単位でチャンク分割し、RAG検索に使える JSONL を出力する。
language: Python
category: Python
environment: Python 3.10+ / PyYAML
updated_at: 2026-04-21
published: true
tags:
  - python
  - rag
  - nlp
  - markdown
  - jsonl
---

## 概要

`data/chunk/` 配下の `.md` / `.txt` ファイルを読み込み、見出しと文字数制限でチャンク分割したうえで JSONL 形式に出力する。  
出力した `chunks.jsonl` は `rag_retrieve.py` や `eval_retrieval.py` の入力として使う。

依存: `PyYAML`（`pip install pyyaml`）

## 基本的な使い方

```bash
python scripts/rag_build_jsonl.py
```

デフォルトで `data/chunk/` を読み、`data/chunks.jsonl` に出力する。

### パスとチャンクサイズを指定する場合

```bash
python scripts/rag_build_jsonl.py \
  --data-dir data/chunk \
  --out data/chunks.jsonl \
  --max-chars 700 \
  --overlap 100
```

## 主なパラメータ

| パラメータ | デフォルト | 説明 |
|---|---|---|
| `--data-dir` | `data/chunk` | 読み込む `.md` / `.txt` のフォルダ |
| `--out` | `data/chunks.jsonl` | 出力先 JSONL パス |
| `--max-chars` | `700` | 1チャンクあたりの最大文字数 |
| `--overlap` | `100` | 隣接チャンク間で重複させる文字数（分割境界の情報損失防止） |

## 入力ファイルの形式

### Markdown + YAML front matter（推奨）

```markdown
---
title: "ライセンス更新手順"
tags: ["ライセンス", "更新"]
source_path: "docs/license.md"
product: "製品A"
topic: "ライセンス"
---

## 更新手順

手順の本文...
```

front matter があれば `title` / `tags` / `source_path` 等がメタデータとして JSONL に含まれる。

### プレーンテキスト（.txt）

front matter なしとして処理される。ファイル名がタイトル代わりになる。

## 出力フィールド

```json
{
  "chunk_id": "sha256:abcd1234...",
  "title": "ライセンス更新手順",
  "source_path": "data/chunk/license.md",
  "tags": ["ライセンス", "更新"],
  "text": "## 更新手順\n手順の本文...",
  "heading_path": "更新手順",
  "chunk_index": 1,
  "product": "製品A",
  "topic": "ライセンス"
}
```

- `chunk_id` は `source_path + 見出しパス + 本文` の SHA-256。内容が変わると ID も変わるため差分検知に使える
- `heading_path` は `H2 > H3` のように連結した見出しのパス

## チャンク分割のロジック

1. Markdown はまず **H1〜H6 の見出し単位**で分割する（コードブロック内の `#` は無視）
2. 見出し単位が `--max-chars` を超えるなら段落（空行区切り）→改行→強制切断の順で再分割する
3. `--overlap` が指定されていると、前チャンクの末尾 N 文字を次チャンクの先頭に付加する

## 注意点

- front matter なしの `.md` は本文全体が 1 チャンクとして処理される（`--max-chars` で再分割はかかる）
- `chunk_id` は内容依存のため、ファイルを編集すると ID が変わる。既存埋め込みキャッシュがある場合は再構築が必要
- Windows パスの `\` は自動で `/` に正規化される

## 使いどころ

- 社内マニュアルや FAQ を Markdown で管理しており、それを RAG の知識ベースにしたい場合
- チャンクIDを使って `eval_retrieval.py` の正解データ（eval CSV）を作る前処理として
