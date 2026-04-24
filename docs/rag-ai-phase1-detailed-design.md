# Phase 1 詳細設計書（静的 RAG MVP）

更新日: 2026-04-22

## 1. 目的

この文書は、Phase 1（自サイト向け静的 RAG MVP）の実装設計を定義します。

ゴールは、GitHub Pages 上の公開済みスクリプト記事だけを根拠にして、ブラウザ上で回答できる AI ページを実装することです。

## 2. スコープ

### 2.1 対象

- `githubpages/_scripts/` の `published: true` 記事
- 静的サイト上で動作する検索 + 回答 UI
- WebLLM を用いたローカル推論
- 回答に対する参照元（source）表示

### 2.2 非対象

- `docs/`, `templates/`, `draft-private/`, `_site/`, `assets/` 配下の補助 Markdown
- `index.md`, `about.md`, `scripts.md`, `tags.md`, `404.md`
- 外部 API（Google AI Studio, OpenAI など）の本格接続
- サーバー側推論・課金・認証

## 3. 成果物

Phase 1 で作成する成果物:

1. コーパス生成スクリプト
2. 検索用 JSON 資産
3. AI ページ（UI）
4. 最小限の手動検証手順

想定ファイル:

- `githubpages/tools/build-rag-corpus.py`
- `githubpages/assets/data/rag-corpus.json`
- `githubpages/assets/data/rag-metadata.json`
- `githubpages/assets/js/rag-search.js`
- `githubpages/assets/js/rag-chat.js`
- `githubpages/assets/css/rag-chat.css`
- `githubpages/rag-ai.md`

## 4. 既存資産の再利用方針

### 4.1 再利用元

- `rag_bot/scripts/rag_build_jsonl.py`

再利用対象の関数・考え方:

- front matter 分離
- 見出し単位分割
- 文字数制限での再分割
- チャンク ID 生成

### 4.2 Phase 1 用に簡略化する点

- Embedding 生成は行わない（lexical search のみ）
- Rerank は行わない
- まずは記事本文 + メタ情報で検索精度を確保する

## 5. データ契約

### 5.1 入力契約（Markdown）

`_scripts` 記事の必須 front matter:

- `title`
- `summary`
- `language`
- `category`
- `environment`
- `updated_at`
- `published`
- `tags`

任意項目:

- `shelf`（未指定時は `category` を表示上の棚名として扱う）
- `ai_summary`
- `ai_exclude`
- `source_url`

### 5.2 出力契約（rag-corpus.json）

各チャンクの最小 schema:

```json
{
  "chunk_id": "sha256:...",
  "title": "...",
  "summary": "...",
  "shelf": "Windows 運用",
  "language": "PowerShell",
  "category": "PowerShell",
  "environment": "Windows PowerShell 5.1+",
  "updated_at": "2026-04-13",
  "tags": ["powershell", "inventory"],
  "source_path": "_scripts/powershell-file-search.md",
  "source_url": "/scripts/powershell-file-search/",
  "heading_path": "概要 > 実行例",
  "chunk_index": 1,
  "text": "..."
}
```

### 5.3 メタ情報（rag-metadata.json）

```json
{
  "generated_at": "2026-04-22T10:00:00+09:00",
  "source": "_scripts published:true only",
  "script_count": 13,
  "chunk_count": 120,
  "version": 1
}
```

## 6. 処理フロー

### 6.1 ビルド時

1. `_scripts/*.md` を走査
2. `published: true` のみ抽出
3. front matter を検証
4. `ai_exclude` 指定見出しを除外しつつチャンク分割
5. `rag-corpus.json` と `rag-metadata.json` を生成

### 6.2 実行時（ブラウザ）

1. AI ページ読み込み時に JSON 資産をロード
2. 質問文を lexical search で検索
3. 上位 N チャンクを context として連結
4. WebLLM へ質問 + context を渡す
5. 回答と参照元一覧を表示

## 7. 検索仕様（Phase 1）

### 7.1 検索方式

- クライアントサイド lexical search
- スコア対象:
  - title
  - summary
  - tags
  - text

### 7.2 初期パラメータ

- `top_k = 4`
- 1 チャンク最大文字数: 700
- オーバーラップ: 100

### 7.3 出力方針

- 参照元は必ず表示
- 根拠なし回答を避けるため、ヒット 0 件時は「該当情報なし」を返す

## 8. UI 設計

### 8.1 ページ構成

`rag-ai.md` に専用ページを追加し、既存ナビ導線を 1 項目だけ増やす。

表示要素:

- 入力欄
- 送信ボタン
- 回答表示エリア
- 参照元リスト
- モデル状態（ロード中 / 利用可 / 非対応）

### 8.2 既存サイトとの整合

- 既存レイアウトを利用する（`default`）
- 既存テーマを維持し、専用 CSS は最小追加に留める
- 既存ページ構造は変更しない

## 9. 非機能要件

### 9.1 パフォーマンス

- 初期対象は `_scripts` のみ（軽量）
- JSON 資産の総量が増えた場合に備え、メタ情報で chunk 数を監視する

### 9.2 可用性

- WebLLM 非対応環境では推論を無効化し、理由を表示する
- 検索だけは継続利用できる形にする

### 9.3 保守性

- コーパス生成は CLI 1 コマンドで再現できる
- schema 変更時は version を更新する

## 10. 検証項目

### 10.1 機能検証

1. `published: true` の記事だけがコーパス化される
2. `published: false` 記事が混入しない
3. 質問に対して上位チャンクが返る
4. 回答に source が表示される
5. WebLLM 非対応時に縮退表示される

### 10.2 データ検証

1. 必須 front matter 欠落時はビルド失敗または警告を出す
2. `source_url` が空でも処理が落ちない
3. JSON schema を満たす

### 10.3 手動確認質問（サンプル）

1. PowerShell で拡張子別のファイル数を集計する方法は？
2. Ollama で embedding を作るスクリプトは？
3. RAG の JSONL を作る手順は？

## 11. タスク分解

### T1: コーパスビルダー実装

- 入力フィルタ実装（`_scripts` + `published:true`）
- front matter 検証
- チャンク生成
- JSON 出力

### T2: AI ページ実装

- `rag-ai.md` 作成
- 検索 JS 実装
- WebLLM 接続 JS 実装
- source 表示 UI 実装

### T3: 導線とスタイル

- ナビゲーション追加
- 最小 CSS 調整

### T4: 検証手順整備

- 実行コマンド
- テスト質問
- 既知制約の記述

## 12. 受け入れ基準

1. 既存ページ（Home / Scripts / Tags / About）の表示崩れがない。
2. AI ページが追加され、最低 3 問で期待する根拠記事を返せる。
3. 公開対象外 Markdown がコーパスに混入しない。
4. Phase 1 の成果物だけで、別環境でも同じ手順で再現可能。

## 13. 工数見積もり（Phase 1 のみ）

| タスク | 目安 |
| --- | --- |
| T1 コーパスビルダー | 1.0-1.5 日 |
| T2 AI ページ | 1.5-2.5 日 |
| T3 導線・UI 調整 | 0.5 日 |
| T4 検証手順整備 | 0.5 日 |

合計: 3.5-5.0 日

## 14. 次フェーズへの引き継ぎ

Phase 2 へ引き継ぐ項目:

- コーパス再生成コマンドの自動化（GitHub Actions）
- front matter lint の自動チェック
- コーパスサイズ監視

Phase 3 へ引き継ぐ項目:

- CMS 投稿時に同じ front matter 契約を強制
- 投稿経路差異の validation
