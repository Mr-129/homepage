# 最終公開チェックリスト

公開先を最後に決める運用では、公開直前に次をまとめて確認すると安全です。

## 1. コンテンツ確認

- APIキーや認証情報が入っていない
- 業務固有情報が入っていない
- メールアドレス、電話番号、住所、個人名など公開したくない個人情報が入っていない
- 公開したくない記事に `published: false` が入っている
- 公開したい記事は `published: true` になっている
- `published: false` の記事が `_scripts/` に残っている場合、それが一覧非表示だけで十分か確認している
- 本当に未出力にしたい記事は公開対象外ディレクトリまたは公開対象外ブランチに分離している
- タイトルと概要が一覧で読める形になっている
- PNG などの画像参照パスが `assets/images/` 基準で正しい
- 画像ファイル名が極端に長くない、分かりやすい

## 2. サイト設定確認

- [_config.yml](../_config.yml) の `url` と `baseurl` が公開先に合っている
- [_data/site_profile.yml](../_data/site_profile.yml) の情報が最終値になっている
- [_config.yml](../_config.yml) と [_data/site_profile.yml](../_data/site_profile.yml) の表示名、アカウント名、URL が意図した公開値になっている
- [.github/workflows/deploy-pages.yml](../.github/workflows/deploy-pages.yml) が正しく設定されている

## 3. 本番想定ビルド確認

```powershell
bundle exec jekyll build
```

## 4. GitHub 側の準備

- 使う GitHub アカウントを決めている
- 公開先リポジトリを作成済み
- ローカルから push できる
- GitHub Pages の Source を **"GitHub Actions"** に設定済み

## 5. ローカル Git 確認

- `main` ブランチで作業内容が整理されている
- 不要な生成物をコミット対象に入れていない
- 公開前に不要ファイルが混ざっていない
- 作業コピーを zip などで共有する場合、`.git/` 配下のログに過去の `user.name` / `user.email` が残ることを理解している
- `.git/` を含めて共有しない運用、または履歴側の個人情報を別途整理する方針を決めている
