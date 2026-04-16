# Windows 簡易セットアップ手順

このページは、リポジトリをローカルでビルド・プレビューするための簡易手順です。予め `Gemfile` が存在することを前提とします。

1. PowerShell を開く（必要に応じて「管理者として実行」）

2. リポジトリのルートに移動し、付属のセットアップスクリプトを実行します:

```powershell
cd path\to\githubpages
powershell -ExecutionPolicy Bypass -File .\tools\setup-windows.ps1 -Serve
```

- `-Serve` を付けるとローカルサーバーが起動します（http://127.0.0.1:4000/）。

3. 手動コマンド（スクリプトを使わない場合）

```powershell
# (必要なら) RubyInstaller をインストール (winget がある場合)
winget install --id RubyInstallerTeam.RubyWithDevKit.3.2 --accept-package-agreements --accept-source-agreements --silent

gem install bundler
bundle install
bundle exec jekyll serve --host 127.0.0.1
```

4. 公開設定の確認

 - 公開時の `url` / `baseurl` は `_config.yml` を編集して実環境の値に合わせてください。
 - デプロイは GitHub Actions で自動実行されます（`main` ブランチへ push 時）。
 - GitHub リポジトリの Settings → Pages → Source を **"GitHub Actions"** に設定してください。

5. トラブルシュート

 - `bundle install` が失敗したら `bundle install --verbose` を試してください。
 - `ruby` / `gem` が見つからない場合は PATH を確認し、PowerShell を再起動してください。

その他ヘルプが必要なら、このドキュメントの更新やスクリプトの微調整を行いますのでログを貼ってください。
