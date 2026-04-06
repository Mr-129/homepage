# 最終公開チェックリスト

公開先を最後に決める運用では、公開直前に次をまとめて確認すると安全です。

## 1. コンテンツ確認

- APIキーや認証情報が入っていない
- 業務固有情報が入っていない
- 公開したくない記事に `published: false` が入っている
- 公開したい記事は `published: true` になっている
- `published: false` の記事が `_scripts/` に残っている場合、それが一覧非表示だけで十分か確認している
- 本当に未出力にしたい記事は公開対象外ディレクトリまたは公開対象外ブランチに分離している
- タイトルと概要が一覧で読める形になっている
- PNG などの画像参照パスが `assets/images/` 基準で正しい
- 画像ファイル名が極端に長くない、分かりやすい

## 2. サイト設定確認

- [_data/site_profile.yml](../_data/site_profile.yml) の情報が最終値になっている
- ユーザーサイトかプロジェクトサイトかを決めている
- 選んだ形式に対応する設定ファイルを更新済み

## 3. 本番想定ビルド確認

ユーザーサイトの場合:

```powershell
bundle exec jekyll build --config _config.yml,_config.publish-user.yml
```

プロジェクトサイトの場合:

```powershell
bundle exec jekyll build --config _config.yml,_config.publish-project.yml
```

## 4. GitHub 側の準備

- 使う GitHub アカウントを決めている
- 公開先リポジトリを作成済み
- ローカルから push できる
- GitHub Pages の公開元を決めている

## 5. ローカル Git 確認

- `main` ブランチで作業内容が整理されている
- 不要な生成物をコミット対象に入れていない
- 公開前に不要ファイルが混ざっていない
