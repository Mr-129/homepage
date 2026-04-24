# Scripts フォルダ分類ガイド

更新日: 2026-04-22

## 目的

`_scripts/` 配下の記事が増えても保守できるよう、フォルダ分類ルールを定義する。

## 結論

`_scripts/` はサブフォルダで分類して運用する。

例:

- `_scripts/powershell/system/`
- `_scripts/powershell/network/`
- `_scripts/powershell/security/`
- `_scripts/python/rag/`
- `_scripts/python/automation/`

## URL ルール

`_config.yml` の collection permalink を次で運用する。

```yml
collections:
  scripts:
    output: true
    permalink: /scripts/:path/
```

この設定により、サブフォルダ構成が URL に反映される。

例:

- `_scripts/powershell/network/dhcp-check.md` -> `/scripts/powershell/network/dhcp-check/`
- `_scripts/python/rag/build-jsonl.md` -> `/scripts/python/rag/build-jsonl/`

## 運用ルール

1. 記事追加時は必ずカテゴリに応じたサブフォルダへ置く。
2. `shelf` で表示上の本棚を指定し、`category` は従来の分類として使う。
3. `title` や `tags` は既存の front matter 契約を守る。
4. `published: false` の記事は RAG コーパスに入れない。
5. 既存記事を移動すると URL が変わる可能性があるため、公開済み記事の移動はまとめて実施する。

## 表示分類と物理配置の違い

- フォルダは保管場所の整理に使う。
- `shelf` は画面上の大きな分類に使う。
- まずは `shelf` を省略して `category` を棚名として使い、必要になったら `shelf` を追加する運用でもよい。

## 推奨分類軸

### 第一階層

- 言語（`powershell`, `python` など）

### 第二階層

- 目的ドメイン（`network`, `system`, `security`, `rag`, `automation` など）

## 移行手順（既存記事を分類する場合）

1. 移動対象の記事を一覧化する。
2. 新しいフォルダ構造を作る。
3. 記事を移動する。
4. `scripts.md` と `tags.md` のリンク動作を確認する。
5. 必要なら旧 URL からのリダイレクト方針を決める。

## 注意点

- `site.scripts` での一覧取得はサブフォルダ化後も継続利用できる。
- 同名ファイルを複数ディレクトリに置く可能性があるため、`:name` ではなく `:path` を使う。
- 将来の CMS 導入時も、このフォルダルールを CMS 側の保存先設定に合わせる。
