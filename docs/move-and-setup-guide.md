# フォルダ移動後の確認と別PCへの再セットアップ

## このドキュメントの目的

この文書は、現在の [githubpages](../) フォルダを別の場所へ移動した場合、または別PCへ持っていく場合に何を確認し、どう再セットアップするかを整理したものです。

想定しているケースは次の2つです。

1. 同じPC内でフォルダだけ移動する
2. 別PCへフォルダを持っていく

## 前提

このサイトは、Jekyll のソース一式を相対パス中心で構成しています。そのため、サイトのソース自体はフォルダを丸ごと移動しても使い回しやすいです。

ただし、Jekyll の実行には Ruby / Bundler 環境が必要です。フォルダだけ移動しても、実行環境そのものは自動では移りません。

## 1. 同じPC内でフォルダを移動した後の確認チェック項目

同じPC内で [githubpages](../) フォルダを移動した場合は、次を確認します。

### 1.1 フォルダを丸ごと移動できているか

- [githubpages](../) フォルダを一式そのまま移動している
- `.git` フォルダも含めて移動している
- [Gemfile](../Gemfile) と [Gemfile.lock](../Gemfile.lock) が残っている
- [_config.yml](../_config.yml) と [_scripts](../_scripts) が残っている

### 1.2 Git 状態の確認

移動先で次を確認します。

```powershell
git status --short
git branch --show-current
git remote -v
```

期待する状態:

- ブランチは `main`
- `remote` はまだ空でもよい
- 変更差分が意図通りに見える

### 1.3 Ruby / Bundler が引き続き使えるか

同じPCなら、Ruby 環境はそのまま使える可能性が高いです。次を確認します。

```powershell
ruby -v
bundle -v
```

もし見つからない場合:

- VS Code のターミナルを開き直す
- VS Code を再起動する
- それでも駄目なら PATH を再確認する

### 1.4 Jekyll ビルド確認

移動先で次を実行します。

```powershell
bundle install
bundle exec jekyll build
```

期待する状態:

- エラーなくビルドが通る
- [_site](../_site) が再生成される

### 1.5 画像と静的ファイルの確認

画像を使っている場合は次も確認します。

- [assets/images](../assets/images) が残っている
- PNG などの画像ファイルが移動できている
- Markdown や HTML の参照パスが崩れていない

## 2. 別PCへ持っていくときの再セットアップ手順

別PCでは、フォルダの移動だけでなく実行環境の再構築が必要です。

### Step 1. フォルダをコピーする

次を含めて [githubpages](../) フォルダを丸ごと持っていきます。

- `.git`
- [Gemfile](../Gemfile)
- [Gemfile.lock](../Gemfile.lock)
- [_config.yml](../_config.yml)
- [_layouts](../_layouts)
- [_includes](../_includes)
- [_scripts](../_scripts)
- [assets](../assets)
- [docs](../docs)

補足:

- Git の履歴を持っていきたいなら `.git` を含める
- 単にサイト内容だけ持っていくなら `.git` なしでもよい

### Step 2. Git の有無を確認する

新しいPCで Git を使うなら、まず確認します。

```powershell
git --version
```

未導入なら Git をインストールします。

### Step 3. Ruby を導入する

Windows では、今回と同じく RubyInstaller + DevKit 構成が扱いやすいです。

例:

```powershell
winget search RubyInstaller --source winget --accept-source-agreements
winget install --id RubyInstallerTeam.RubyWithDevKit.3.2 --source winget --accept-source-agreements --accept-package-agreements --silent
```

### Step 4. Ruby / Bundler を確認する

新しいPCで次を確認します。

```powershell
ruby -v
gem -v
bundle -v
```

もし `bundle` が無ければ:

```powershell
gem install bundler
```

### Step 5. 依存関係を入れ直す

プロジェクトルートで次を実行します。

```powershell
bundle install
```

ポイント:

- [Gemfile.lock](../Gemfile.lock) があるため、元環境に近い依存関係を再現しやすい
- Windows では `tzinfo-data` が必要になるため、現行の [Gemfile](../Gemfile) の内容はそのまま維持する

### Step 6. Jekyll ビルド確認をする

まずはサーバー起動前にビルド確認をします。

```powershell
bundle exec jekyll build
```

これが通れば、構成ファイルと依存関係は概ね正しいです。

### Step 7. ローカルプレビューを確認する

次にローカルサーバーを起動します。

```powershell
bundle exec jekyll serve --host 127.0.0.1
```

確認 URL:

- `http://127.0.0.1:4000/`

### Step 8. Git 状態を確認する

`.git` を含めて持ってきた場合は、次を確認します。

```powershell
git status --short
git branch --show-current
git remote -v
```

確認ポイント:

- ローカル履歴が残っているか
- 現在のブランチが意図通りか
- `remote` をまだ設定していないなら空で問題ない

## 3. 別PC移行時のトラブル確認ポイント

### 3.1 `ruby` や `bundle` が見つからない

確認ポイント:

- Ruby のインストールが完了しているか
- 新しいターミナルを開き直したか
- PATH が反映されているか

### 3.2 `bundle install` が失敗する

確認ポイント:

- ネットワーク接続があるか
- Ruby と Bundler のバージョンが極端にずれていないか
- `Gemfile` を勝手に変更していないか

### 3.3 `jekyll serve` が失敗する

確認ポイント:

- 先に `bundle exec jekyll build` が通るか
- Windows の場合、[Gemfile](../Gemfile) の `tzinfo-data` が消えていないか

### 3.4 画像が表示されない

確認ポイント:

- PNG が [assets/images](../assets/images) にあるか
- 参照パスに `relative_url` を使っているか
- ファイル名の大文字小文字やスペルがずれていないか

## 4. 最小の再確認コマンド一覧

移動後や別PCで最低限確認するなら、次の順で十分です。

```powershell
git status --short
ruby -v
bundle -v
bundle install
bundle exec jekyll build
bundle exec jekyll serve --host 127.0.0.1
```

## 5. まとめ

要点だけまとめると次の通りです。

1. フォルダ丸ごとの移動なら、ソース構成はそのまま使いやすい
2. 同じPCなら Ruby 環境もそのまま使える可能性が高い
3. 別PCでは Ruby / Bundler / Jekyll の再セットアップが必要
4. まず `bundle exec jekyll build` が通るかを見るのが早い
5. Git の履歴を引き継ぎたいなら `.git` も一緒に持っていく
