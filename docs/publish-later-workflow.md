# 公開先を最後に決める運用

## この構成の考え方

このサイトは、先にコンテンツとJekyll構成を育てておき、公開先のGitHubアカウントとリポジトリは最後に選べるようにしてあります。

公開先を後回しにするために、次の2つを分離しています。

1. サイトそのものの内容
2. GitHub Pages 用の公開設定

この分離により、日常の追加作業では公開URLやアカウント名をほとんど意識しなくてよくなります。

## このワークスペースで分離しているもの

- 一般設定: [_config.yml](../_config.yml)
- ユーザーサイト公開用の上書き設定: [_config.publish-user.yml](../_config.publish-user.yml)
- プロジェクトサイト公開用の上書き設定: [_config.publish-project.yml](../_config.publish-project.yml)
- ナビゲーション: [_data/navigation.yml](../_data/navigation.yml)
- サイト基本情報: [_data/site_profile.yml](../_data/site_profile.yml)

## 普段の運用

普段は、公開先をまだ決めなくてよいので、ローカルでは通常の設定だけで作業します。

```powershell
bundle exec jekyll serve --host 127.0.0.1
```

この段階では、`url` と `baseurl` は本番確定値でなくて問題ありません。

## 最後に公開先を選ぶときの分岐

### パターン 1. ユーザーサイトとして公開する

公開URLは次になります。

- `https://YOUR_GITHUB_USERNAME.github.io/`

使う設定ファイル:

- [_config.yml](../_config.yml)
- [_config.publish-user.yml](../_config.publish-user.yml)

ローカルでの本番想定ビルド例:

```powershell
bundle exec jekyll build --config _config.yml,_config.publish-user.yml
```

### パターン 2. プロジェクトサイトとして公開する

公開URLは次になります。

- `https://YOUR_GITHUB_USERNAME.github.io/YOUR_REPOSITORY_NAME/`

使う設定ファイル:

- [_config.yml](../_config.yml)
- [_config.publish-project.yml](../_config.publish-project.yml)

ローカルでの本番想定ビルド例:

```powershell
bundle exec jekyll build --config _config.yml,_config.publish-project.yml
```

## 最後の公開手順

完成後に公開するなら、手順は次の通りです。

1. GitHubアカウントを最終決定する
2. ユーザーサイトかプロジェクトサイトかを選ぶ
3. 選んだ形式に合わせて [_config.publish-user.yml](../_config.publish-user.yml) または [_config.publish-project.yml](../_config.publish-project.yml) のプレースホルダを置き換える
4. [_data/site_profile.yml](../_data/site_profile.yml) の GitHub 情報を更新する
5. GitHub 上にリポジトリを作る
6. ローカルを Git リポジトリ化して push する
7. GitHub Pages を有効化する

## 長期運用での利点

- 公開先が未確定でも記事作成を進められる
- ユーザーサイトとプロジェクトサイトを最後に選べる
- URL依存の変更が少数ファイルに閉じる
- ナビゲーションや基本情報を一箇所で管理できる

## 日常追加時のルール

長期運用では、次の流れを基本にすると崩れにくいです。

1. `_scripts/` に記事を追加する
2. `templates/script-template.md` をベースに書く
3. 画像を使う場合は `assets/images/` に置く
4. 最初は `published: false` のまま作業する
5. ローカルで確認する
6. 問題なければ Git に保存する
7. 公開は最後にまとめて行う

補足:
- `published: false` は一覧非表示のための目印であり、強い非公開設定ではない
- 本当に未出力にしたい記事は `_scripts/` の外で管理する
- 将来的に公開用の自動コピー処理を入れるまでは、運用で分離する前提にする

## 現在のローカル状態

現時点では、ローカル Git リポジトリの初期化は完了しています。

- ブランチは `main`
- `remote` は未設定
- 公開先の GitHub アカウントはまだ未決定

このため、しばらくはローカル保存だけ進めて、最後に GitHub 側へ接続する進め方ができます。
