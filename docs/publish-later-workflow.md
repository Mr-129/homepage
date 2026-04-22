# デプロイと公開の運用

## 現在の構成

このサイトは GitHub Actions（公式方式）で自動デプロイされます。

- `main` ブランチに push すると自動でビルド・公開される
- 公開設定は `_config.yml` と `_data/site_profile.yml` に集約
- GitHub リポジトリの Settings → Pages → Source は **"GitHub Actions"** を選択

## ワークスペースの設定ファイル

- 一般設定: [_config.yml](../_config.yml)
- ナビゲーション: [_data/navigation.yml](../_data/navigation.yml)
- サイト基本情報: [_data/site_profile.yml](../_data/site_profile.yml)
- デプロイワークフロー: [.github/workflows/deploy-pages.yml](../.github/workflows/deploy-pages.yml)

## 普段の運用

ローカルでは通常の設定だけで作業します。

```powershell
bundle exec jekyll serve --host 127.0.0.1
```

## 公開の流れ

1. ローカルで記事を追加・編集する
2. `bundle exec jekyll serve` で確認する
3. 公開プロフィール値と個人情報の混入有無を確認する
4. `main` ブランチに commit & push する
5. GitHub Actions が自動でビルド・デプロイする

## 日常追加時のルール

長期運用では、次の流れを基本にすると崩れにくいです。

1. `_scripts/` に記事を追加する
2. `templates/script-template.md` をベースに書く
3. 画像を使う場合は `assets/images/` に置く
4. 最初は `published: false` のまま作業する
5. ローカルで確認する
6. 問題なければ `published: true` にして push する

補足:
- `published: false` は一覧非表示のための目印であり、強い非公開設定ではない
- 本当に出力したくない原稿は `draft-private/` に置く（`_config.yml` の exclude で除外済み）
- 本当に未出力にしたい記事は `_scripts/` の外で管理する
- 公開サイトに出る表示名や URL は `_config.yml` と `_data/site_profile.yml` の値がそのまま使われる
- 作業コピーをそのまま共有する場合、`.git/` のログに過去の `user.email` が残ることがあるため、通常は `.git/` を除外して共有する
- 将来的に公開用の自動コピー処理を入れるまでは、運用で分離する前提にする

## Git 接続時の確認事項

GitHub へ push する前に、次を確認します。

- `origin` が意図した公開先リポジトリを向いている
- push に使う GitHub アカウントが公開先の運用方針に合っている
- `git config user.name` と `git config user.email` が意図した公開者情報になっている
- 作業コピーを外部共有する場合は `.git/` を含めない
