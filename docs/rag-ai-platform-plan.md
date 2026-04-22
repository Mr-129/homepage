# RAG AI プラットフォーム計画

更新日: 2026-04-21

## この文書の目的

この文書は、GitHub Pages で公開している Markdown コンテンツと `rag_bot` の資産を統合し、公開済みの内容を根拠に回答できる RAG AI を段階的に構築するための計画書です。

最初は自分のサイトで成立させ、その後に「だれでも自分の Web サイトへ導入できる」テンプレート製品へ切り出すことを前提にしています。

## 目指す状態

1. GitHub Pages 上の公開コンテンツを根拠に回答できる AI ページがある。
2. 既存の Jekyll 構成を壊さず、静的サイトとして運用できる。
3. 投稿は Git ベースで管理し、非エンジニア向け UI 投稿とエンジニア向けエディタ編集を両立できる。
4. 生成 AI の実行基盤は段階的に拡張し、当初は WebLLM、将来は Google AI Studio や OpenAI 互換 API へ切り替えられる。
5. 最終的に Jekyll / GitHub Pages 利用者向けのテンプレート製品として再利用できる。

## 現時点の前提

- 正本コンテンツは `githubpages` 配下の Markdown とする。
- `rag_bot` は実行時サーバーとしては使わず、当面は前処理と将来のプロキシ基盤として再利用する。
- MVP は static-first とし、GitHub Pages 単体で動く範囲を優先する。
- 初期ターゲットは GitHub Pages / Jekyll 利用者とする。
- 最初の収益化はテンプレート販売 + 導入支援とする。

## Phase 0 で確定したこと

### RAG 対象の境界

初期の RAG 対象は `githubpages/_scripts/` 配下の `published: true` の記事だけに限定します。

初期の RAG 対象に含めるもの:

- `githubpages/_scripts/` の公開済み記事

初期の RAG 対象から除外するもの:

- `githubpages/_site/`
- `githubpages/docs/`
- `githubpages/templates/`
- `githubpages/draft-private/`
- `githubpages/assets/` 配下の補助 Markdown
- `githubpages/README.md`
- `index.md`
- `about.md`
- `scripts.md`
- `tags.md`
- `404.md`

補足:

- `published: false` は一覧非表示だけでなく、RAG コーパスからも除外条件として扱う。
- `published: false` は強い非公開設定ではないため、コーパス生成側でも必ず除外する。

### front matter 契約

`_scripts/` 配下の記事は、次の front matter を標準契約とします。

| 項目 | 必須 | 用途 |
| --- | --- | --- |
| `title` | 必須 | 記事タイトル、検索結果表示、回答の出典表示 |
| `summary` | 必須 | 一覧表示、検索結果プレビュー、短い説明 |
| `language` | 必須 | 言語別の表示と分類 |
| `category` | 必須 | UI 上の分類、今後の CMS 入力項目 |
| `environment` | 必須 | 実行条件、注意点の把握 |
| `updated_at` | 必須 | 更新日時の管理、鮮度表示 |
| `published` | 必須 | 一覧表示と RAG 取り込みの制御 |
| `tags` | 必須 | 分類、検索補助 |

補足:

- `layout` は [_config.yml](../_config.yml) の defaults に任せる。
- テンプレートの基準は [templates/script-template.md](../templates/script-template.md) とする。
- 実データの基準は [_scripts/python-rag-build-jsonl.md](../_scripts/python-rag-build-jsonl.md) などの公開済み記事とする。

### AI 用の任意項目

AI 用の補助項目は後方互換を保った任意項目として導入可能にします。

| 項目 | 必須 | 用途 |
| --- | --- | --- |
| `ai_summary` | 任意 | AI が引用しやすい補足要約 |
| `ai_exclude` | 任意 | 特定見出しや補足節をコーパスから除外したい場合に使う |
| `source_url` | 任意 | 参考元や出典 URL を持たせたい場合に使う |

初期段階では、これらを既存記事へ一斉に強制しません。必要な記事から段階的に追加します。

## アーキテクチャ方針

### コンテンツ層

- GitHub Pages の Markdown を正本にする。
- 公開対象と RAG 対象の境界は front matter とディレクトリ構成で制御する。
- CMS 投稿でもエディタ手編集でも、最終的に同じ Markdown 契約へ落とし込む。

### 前処理層

- `rag_bot/scripts/rag_build_jsonl.py` の Markdown 解析とチャンク分割ロジックを再利用する。
- GitHub Pages 用のコーパスビルダーを別途用意し、公開済み `_scripts` だけから JSON 資産を生成する。
- Python は実行時依存ではなく、ビルド時の前処理専用に寄せる。

### 実行層

- MVP はブラウザ内検索 + WebLLM を採用する。
- 初期は静的サイトだけで動かし、検索対象も小さく保つ。
- 大規模コンテキスト、共有課金、秘密鍵管理が必要になった時点でサーバーやプロキシを導入する。

### LLM プロバイダ層

- 初期既定: WebLLM
- 将来候補: Google AI Studio、OpenAI 互換 API、GitHub Copilot 系、Ollama
- プロバイダごとの差は provider abstraction で吸収する。
- ブラウザからの直接 API キー入力は expert mode 扱いとし、既定の導線にはしない。

## 段階計画

### Phase 0: コンテンツ契約の固定

目的:

- RAG 対象の境界と front matter 契約を固定する。

主な成果物:

- RAG 対象の include / exclude ルール
- `_scripts` の front matter 契約
- AI 補助項目の導入方針

完了条件:

- 何をコーパスへ入れるかが明確である。
- CMS 投稿と手編集が同じ契約で共存できる。

### Phase 1: 自サイト向け静的 RAG MVP

目的:

- GitHub Pages 上の公開済みスクリプトだけを使い、静的サイト上で回答できる AI ページを作る。

主な成果物:

- GitHub Pages 用コーパスビルダー
- 公開用 JSON 資産
- WebLLM を使う AI ページ
- 根拠表示付きの回答 UI

完了条件:

- 少数の代表質問に対して、正しい記事を根拠として返せる。
- 既存のサイト構成を壊さずに AI ページを追加できる。

### Phase 2: ビルドと公開の自動化

目的:

- Markdown 更新時にコーパスを安定再生成できるようにする。

主な成果物:

- コーパス再生成コマンドまたは GitHub Actions
- front matter と公開範囲の検査
- コーパス肥大化や漏れを検知するチェック手順

完了条件:

- 手動運用に依存せず、更新時に同じルールでコーパスが再生成される。

### Phase 3: 投稿の二刀流

目的:

- 非エンジニア向けの投稿 UI と、エンジニア向けのエディタ編集を両立する。

主な成果物:

- Git ベース CMS の導入
- 投稿 UI から `_scripts/` へ Markdown を commit する流れ
- 手編集と CMS 投稿が同じ validation を通る運用

完了条件:

- UI から投稿した記事も、エディタから書いた記事も同じ build と RAG 生成に乗る。

### Phase 4: 複数 LLM ルーティング

目的:

- WebLLM 以外の生成 AI を差し替え可能にする。

主な成果物:

- provider abstraction
- 将来のプロキシ導入前提の設定構造
- コンテキスト量やコストに応じた使い分け方針

完了条件:

- 将来プロキシを足しても、フロントの契約とコンテンツ schema を維持できる。

### Phase 5: テンプレート製品化

目的:

- 自分のサイト向け構成を、他者が再利用できるスターターキットへ切り出す。

主な成果物:

- Jekyll 用スターターキット
- 導入ドキュメント
- CMS 設定例
- AI ページの雛形

完了条件:

- 別リポジトリへコピーしても、手順書だけで初期導入できる。

### Phase 6: 収益化の段階導入

目的:

- 技術資産を売れる形に整理する。

主な成果物:

- テンプレート販売パッケージ
- 導入支援メニュー
- 検索チューニングや外部 LLM 接続支援のメニュー化

完了条件:

- 無料配布する部分と有料提供する部分の境界が明確になっている。

## 難易度と工数の目安

| 範囲 | 難易度 | 工数の目安 |
| --- | --- | --- |
| Phase 0-2 の自サイト向け MVP | 中 | 5-9 日 |
| Phase 3 の CMS 導入 | 中 | 追加 2-4 日 |
| Phase 4 の multi-provider + optional proxy | 中高 | 追加 4-8 日 |
| Phase 5-6 のテンプレート化と販売準備 | 中高 | 追加 5-10 日 |

補足:

- ホスト型 SaaS は別枠の高難度とし、この計画の初期範囲には含めない。
- 実装の難しさは AI モデルの接続そのものより、公開範囲管理、秘密鍵管理、運用設計の方が大きい。

## 収益化方針

初期は次を売り物にします。

- Jekyll / GitHub Pages 向けテンプレート
- 導入支援
- 検索チューニング支援
- 外部 LLM 接続支援

初期段階では、ホスト型 SaaS を先に作らず、テンプレート販売 + 導入支援を優先します。

理由:

- 秘密鍵管理と API コストの負担を初期から抱えずに済む。
- 少人数でも成立しやすい。
- 実際の導入事例を集めながら設計を磨ける。

将来の拡張候補:

- 有料アドオン
- 複数サイト運用向け支援
- プロキシを伴うホスト型プラン

## リスクと対策

### `published: false` の扱い

リスク:

- 一覧には出なくても、Jekyll の出力や前処理側で拾われる可能性がある。

対策:

- コーパス生成側でも `published: true` のみを二重に確認する。

### WebLLM の実行条件

リスク:

- ブラウザや端末性能によっては動作しない、または重い。

対策:

- 非対応時の縮退表示を用意する。
- 最初は対象コンテンツ量を小さく保つ。

### 外部 API と秘密鍵管理

リスク:

- Google AI Studio や OpenAI 系を扱う段階で、ブラウザ直接利用だけでは安全に運用しづらい。

対策:

- 初期既定は WebLLM にする。
- 外部 API 本格導入時にプロキシ層を追加する。

### CMS と手編集の差異

リスク:

- 投稿経路によって front matter や本文構造が崩れる。

対策:

- Markdown 契約を先に固定し、同じ validation を通す。

## 次にやること

1. Phase 1 の詳細設計を作る。（作成済み: [rag-ai-phase1-detailed-design.md](rag-ai-phase1-detailed-design.md)）
2. `_scripts/` から公開コーパスを生成する設計を詰める。（分類ルール: [script-folder-organization.md](script-folder-organization.md)）
3. 代表質問を用意して、MVP の検証観点を決める。
