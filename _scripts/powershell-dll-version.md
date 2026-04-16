---
title: DLL のアセンブリバージョンを一括取得する
summary: 指定フォルダ内の DLL を走査し、.NET アセンブリバージョンをテーブル表示する。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+ / .NET Framework
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - dll
  - inventory
  - dotnet
---

## 概要

ビルド成果物やライブラリフォルダ内の DLL について、アセンブリバージョンを一括取得して確認するスクリプト。ネイティブ DLL は `.NET assembly` ではないためスキップされる。

## 実行例

```powershell
$dir = "C:\path\to\dlls"

Get-ChildItem $dir -Filter *.dll -Recurse |
  ForEach-Object {
    try {
      $an = [System.Reflection.AssemblyName]::GetAssemblyName($_.FullName)
      [pscustomobject]@{
        Dll             = $_.Name
        AssemblyVersion = $an.Version.ToString()
      }
    } catch {
      [pscustomobject]@{
        Dll             = $_.Name
        AssemblyVersion = "(not .NET assembly)"
      }
    }
  } |
  Sort-Object Dll |
  Format-Table -AutoSize
```

## 注意点

- ネイティブ DLL（C++ 等）は `GetAssemblyName` で例外が出るため catch でスキップしている
- `FileVersion` ではなく `AssemblyVersion` を取得している点に注意
- `FileVersionInfo` が必要な場合は `[System.Diagnostics.FileVersionInfo]::GetVersionInfo()` を使う

## 使いどころ

- デプロイ前のバージョン確認
- ライブラリのバージョン不整合の調査
- リリース物の棚卸し
