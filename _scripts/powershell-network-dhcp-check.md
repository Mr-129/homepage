---
title: DHCP 設定を確認する
summary: ネットワークアダプタの IP アドレス取得方法（DHCP / 固定）を確認するワンライナー。
language: PowerShell
category: PowerShell
environment: Windows PowerShell 5.1+ / Windows 10・11
updated_at: 2026-04-13
published: true
tags:
  - powershell
  - network
  - inventory
---

## 概要

ネットワークアダプタの IP アドレスが DHCP で取得されているか、固定設定かを確認するスクリプト。

## 実行例

```powershell
(Get-NetIPAddress -InterfaceAlias "イーサネット" -AddressFamily "IPv4").PrefixOrigin
```

## 出力の意味

| 値 | 意味 |
|---|---|
| Dhcp | DHCP でアドレスを取得 |
| Manual | 固定 IP アドレス |

## すべてのアダプタを確認

```powershell
Get-NetIPAddress -AddressFamily IPv4 |
  Select-Object InterfaceAlias, IPAddress, PrefixOrigin |
  Format-Table -AutoSize
```

## 注意点

- `InterfaceAlias` は環境によって「イーサネット」「Wi-Fi」「Ethernet」等異なる
- 仮想アダプタも表示されるため、物理アダプタだけ確認したい場合はフィルタが必要

## 使いどころ

- ネットワーク設定の確認
- DHCP / 固定 IP の棚卸し
