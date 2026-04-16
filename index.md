---
title: Home
description: 使用したスクリプトを整理して残すためのJekyllベースの個人サイト
layout: default
---
<section class="hero shell">
  <div class="hero-panel">
    <div class="hero-copy">
      <p class="eyebrow">Copper File Archive</p>
      <h1>使ったスクリプトを、書庫のように整理して残す</h1>
      <p>このホームページでは、実際に使ったスクリプトを用途、実行条件、再利用の前提とあわせて保管しています。見た目は Copper File を基準に、あとで探し直しやすい記録庫として整えています。</p>
      <div class="hero-actions">
        <a class="button" href="{{ '/scripts/' | relative_url }}">スクリプト一覧を見る</a>
        <a class="button-secondary" href="{{ '/about/' | relative_url }}">保管方針を見る</a>
      </div>
    </div>
    <div class="hero-side">
      <div class="info-card">
        <h2>現在の保管棚</h2>
        <a class="metric metric-link" href="{{ '/scripts/?tag=powershell' | relative_url }}"><span>Drawer 01</span><strong>PowerShell</strong></a>
        <a class="metric metric-link" href="{{ '/scripts/?tag=いたずら用' | relative_url }}"><span>Drawer 02</span><strong>いたずら用</strong></a>
        <div class="metric"><span>Expansion</span><strong>必要になったら棚を追加</strong></div>
      </div>
      <div class="info-card">
        <h2>保管ルール</h2>
        <p>まずは使ったものを迷わず残し、あとで見返すときに必要な条件だけを先に固定します。分類は増えすぎないよう段階的に拡張します。</p>
      </div>
    </div>
  </div>
</section>

<section class="shell page-section">
  <header class="section-header">
    <p class="eyebrow">Archive Structure</p>
    <h2>現時点では2つの棚で記録を整理する</h2>
    <p class="section-lead">細かく分類しすぎず、まずは PowerShell と いたずら用 の2区分で運用します。保管場所が増えるのは実データが増えてからで十分です。</p>
  </header>
  <div class="section-grid">
    <a class="content-card content-card-link" href="{{ '/scripts/?tag=powershell' | relative_url }}">
      <h2>PowerShell</h2>
      <p>日常作業、自動化、ファイル操作、確認系のスクリプトを保管する主棚です。再利用頻度が高いものを中心に残します。</p>
    </a>
    <a class="content-card content-card-link" href="{{ '/scripts/?tag=いたずら用' | relative_url }}">
      <h2>いたずら用</h2>
      <p>軽い遊びやネタ用途のスクリプトを分けて置く補助棚です。本番用途の記録と混ざらないよう独立して扱います。</p>
    </a>
    <article class="content-card">
      <h2>追加予定の棚</h2>
      <p>件数が増えた段階で、用途別や言語別の保管棚を追加します。最初から分けすぎず、取り出しにくくしない方針です。</p>
    </article>
  </div>
</section>
