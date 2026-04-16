---
title: Windows Sandbox で PowerShell 検証用の使い捨て環境を作る
summary: PowerShell の動作確認や破壊的な検証を安全に試すために、Windows Sandbox を使って一時的な検証環境を用意する手順。
language: PowerShell
category: PowerShell
environment: Windows 10/11 Pro, Enterprise, Education
updated_at: 2026-03-27
published: true
tags:
  - powershell
  - windows-sandbox
  - virtualization
  - test-environment
---
## 概要

PowerShell の検証では、レジストリ変更、ファイル削除、実行ポリシー変更、モジュール導入など、元の PC に直接試したくない操作が出ることがあります。

そのときは、まず Windows Sandbox を使って、壊しても問題ない一時的な Windows 環境を用意してから試す方が安全です。

Windows Sandbox は、起動のたびに初期状態へ戻る使い捨ての仮想環境です。仮想マシンをフル作成するより軽く、PowerShell の疎通確認や危険寄りのスクリプト検証に向いています。

## 使いどころ

- PowerShell の削除系コマンドを試したい
- 実行ポリシーや管理者権限まわりの挙動を確認したい
- モジュール導入やスクリプト実行で PC を汚したくない
- 検証後に環境を毎回まっさらに戻したい

## 前提条件

Windows Sandbox は、基本的に次の環境で使います。

- Windows 10/11 Pro
- Windows 10/11 Enterprise
- Windows 10/11 Education
- BIOS/UEFI で仮想化支援機能が有効
- Windows の機能で Windows Sandbox を有効化できること

今回確認できた範囲では、作業端末は Windows 10 Pro で、Hyper-V 系のハイパーバイザーは見えています。
ただし、Windows Sandbox 機能そのものの有効状態確認は管理者権限が必要でした。

## 入力

- 管理者権限での Windows 機能設定
- 検証したい PowerShell スクリプト
- 必要なら Sandbox に渡す共有フォルダ

## 出力

- 起動のたびに初期化される Windows Sandbox 環境
- PowerShell を安全に試せる一時検証環境
- 必要なら `.wsb` 設定ファイル経由で再利用できる起動手順

## 手順

### 1. Windows Sandbox を有効化する

GUI で行う場合:

1. 「Windows の機能の有効化または無効化」を開く
2. `Windows Sandbox` にチェックを入れる
3. 必要に応じて再起動する

PowerShell で行う場合は、管理者権限で次を実行します。

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All -NoRestart
Restart-Computer
```

補足:

- 管理者権限がないと、この操作は失敗します
- 会社 PC では機能追加がポリシーで制限されていることがあります

### 2. Windows Sandbox を起動する

スタートメニューから `Windows Sandbox` を起動します。

起動後は、毎回まっさらな Windows が立ち上がります。
ここに PowerShell を開いて、検証したい処理を試します。

### 3. まずは危険度の低いコマンドで疎通確認する

初回は、破壊系コマンドを入れる前に PowerShell 自体の動作確認をします。

```powershell
$PSVersionTable
Get-ExecutionPolicy -List
Get-ChildItem Env:
New-Item -ItemType Directory C:\work -Force
Set-Location C:\work
"sandbox ready" | Out-File .\ready.txt -Encoding utf8
Get-ChildItem C:\work
```

ここまで通れば、Sandbox 内で PowerShell 実行ができる状態です。

### 4. 検証対象を共有フォルダ経由で持ち込む

毎回コピペするより、ホスト側に作業用フォルダを作って Sandbox に渡す方が扱いやすいです。

例:

- ホスト側: `C:\sandbox-share`
- 中身: 検証スクリプト、テキスト、ログ保存先

### 5. `.wsb` ファイルで Sandbox 起動を固定化する

同じ検証を繰り返すなら、`.wsb` を使うと起動設定を保存できます。

例:

```xml
<Configuration>
  <MappedFolders>
    <MappedFolder>
      <HostFolder>C:\sandbox-share</HostFolder>
      <SandboxFolder>C:\Users\WDAGUtilityAccount\Desktop\sandbox-share</SandboxFolder>
      <ReadOnly>false</ReadOnly>
    </MappedFolder>
  </MappedFolders>
  <LogonCommand>
    <Command>powershell.exe -ExecutionPolicy Bypass -File C:\Users\WDAGUtilityAccount\Desktop\sandbox-share\bootstrap.ps1</Command>
  </LogonCommand>
</Configuration>
```

この `.wsb` をダブルクリックすると、共有フォルダ付きで Sandbox を起動できます。

### 6. 初期セットアップ用 `bootstrap.ps1` を置く

共有フォルダに `bootstrap.ps1` を置いておくと、起動直後に PowerShell 検証の準備を自動化できます。

例:

```powershell
$workspace = 'C:\work'
New-Item -ItemType Directory -Path $workspace -Force | Out-Null
Set-Location $workspace

Start-Transcript -Path "$workspace\session.log" -Force

Write-Host 'PowerShell sandbox bootstrap start'
$PSVersionTable | Out-File "$workspace\psversion.txt" -Encoding utf8
Get-ExecutionPolicy -List | Out-File "$workspace\execution-policy.txt" -Encoding utf8

Write-Host 'ready'
Stop-Transcript
```

## 実行例

管理者 PowerShell で機能を有効化する例:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All -NoRestart
Restart-Computer
```

Sandbox 内で削除系の練習をする前の準備例:

```powershell
New-Item -ItemType Directory C:\lab -Force
1..5 | ForEach-Object { "sample $_" | Out-File "C:\lab\file$_.txt" -Encoding utf8 }
Get-ChildItem C:\lab
Remove-Item C:\lab\file1.txt -WhatIf
```

`-WhatIf` を併用すると、最初から破壊的に実行せず確認しながら進められます。

## 注意点

- Windows Home では通常は使えません
- Windows Sandbox の有効化は管理者権限が必要です
- 共有フォルダを読み書き可にすると、ホスト側のファイルは壊せます
- 本当に壊してよい検証だけを Sandbox で試す方が安全です
- 共有フォルダは専用の捨てフォルダを使い、通常の作業フォルダを直接渡さない方がよいです

## 公開状態

- 現在は下書きのため `published: false`
- 公開対象にするなら内容確認後に `published: true` へ変更する

## 補足

この手順は「PowerShell を安全に壊しながら試す場所を最初に作る」ことを目的にしています。
PowerShell の検証対象が管理者権限、削除、レジストリ変更、実行ポリシー変更を含むなら、先に Sandbox を作る流れを標準手順にした方が事故を減らせます。

## 画像を添付する方法（このドキュメントへの追加手順）

手順に画像を添えると視認性が上がります。画像はリポジトリ内に格納し、Markdown から参照します。推奨の置き場所と書き方は次のとおりです。

- 画像置き場（リポジトリ内）: `assets/images/windows-sandbox/`
- ファイル名ルール: `screenshot-01.png`, `screenshot-02.png` のように連番で分かりやすく
- 推奨フォーマット: `png` または `webp`（写真は `jpg` でも可）。ファイルサイズは 200–400KB 目安

Markdown に挿入する例:

```markdown
![Sandbox 起動画面](../../assets/images/windows-sandbox/screenshot-01.png)
*図1: Windows Sandbox 起動画面（例）*
```

注意点:
- `_config.yml` で `baseurl` を設定している場合はパスを `{{ site.baseurl }}/assets/images/...` のように調整してください。
- 大きな画像は `assets/images/windows-sandbox/` に `-small` 版を作り、リンク先に高解像度版を置く運用も有効です。

画像はこのリポジトリにまだ追加していません。画像ファイルを手元で準備して `assets/images/windows-sandbox/` に配置していただければ、上の Markdown 例で表示されます。