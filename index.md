---
title: Home
description: 使用したスクリプトを整理して残すためのJekyllベースの個人サイト
layout: default
---
{% comment %}
  トップページの「現在の保管棚」は手書きではなく、公開済み記事から自動生成する。
  shelf が無い既存記事でも表示できるように、category を棚名の代替として使う。
{% endcomment %}
{% assign visible_scripts = site.scripts | where_exp: 'item', 'item.published == true' %}
{% assign all_shelves = "" | split: "" %}
{% for script in visible_scripts %}
  {% assign script_shelf = script.shelf | default: script.category | default: '未分類' %}
  {% unless all_shelves contains script_shelf %}
    {% assign all_shelves = all_shelves | push: script_shelf %}
  {% endunless %}
{% endfor %}
{% assign all_shelves = all_shelves | sort %}
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
        {% for shelf in all_shelves %}
          {% comment %}
            各棚に何件の記事があるかを数え、一覧ページの shelf フィルタ付き URL へリンクする。
          {% endcomment %}
          {% assign shelf_count = 0 %}
          {% for s in visible_scripts %}
            {% assign script_shelf = s.shelf | default: s.category | default: '未分類' %}
            {% if script_shelf == shelf %}
              {% assign shelf_count = shelf_count | plus: 1 %}
            {% endif %}
          {% endfor %}
        <a class="metric metric-link" href="{{ '/scripts/' | relative_url }}?shelf={{ shelf | url_encode }}"><span>Drawer {{ forloop.index }}</span><strong>{{ shelf }} ({{ shelf_count }})</strong></a>
        {% endfor %}
        <div class="metric"><span>Expansion</span><strong>{{ all_shelves.size }} 棚で運用中</strong></div>
      </div>
      <div class="info-card">
        <h2>保管ルール</h2>
        <p>まずは使ったものを迷わず残し、あとで見返すときに必要な条件だけを先に固定します。本棚は段階的に増やし、記事が増えたら棚ごとに整理します。</p>
      </div>
    </div>
  </div>
</section>

<section class="shell page-section">
  <header class="section-header">
    <p class="eyebrow">Archive Structure</p>
    <h2>本棚ごとに記録を整理する</h2>
    <p class="section-lead">記事は本棚単位でまとめて扱い、必要に応じて棚を追加します。既存記事は `shelf` 未指定でもカテゴリを棚名として扱えるため、段階的に移行できます。</p>
  </header>
  <div class="section-grid">
    {% for shelf in all_shelves %}
      {% comment %}
        下のカード群もトップの保管棚一覧と同じ棚定義を使う。
        これにより、トップと一覧ページで棚の名前が食い違わない。
      {% endcomment %}
      {% assign shelf_count = 0 %}
      {% for s in visible_scripts %}
        {% assign script_shelf = s.shelf | default: s.category | default: '未分類' %}
        {% if script_shelf == shelf %}
          {% assign shelf_count = shelf_count | plus: 1 %}
        {% endif %}
      {% endfor %}
    <a class="content-card content-card-link" href="{{ '/scripts/' | relative_url }}?shelf={{ shelf | url_encode }}">
      <h2>{{ shelf }}</h2>
      <p>{{ shelf }} に分類した記事をまとめて表示します。現在 {{ shelf_count }} 件です。</p>
    </a>
    {% endfor %}
    <article class="content-card">
      <h2>追加予定の棚</h2>
      <p>件数が増えた段階で、必要な棚だけを追加します。最初から分けすぎず、取り出しにくくしない方針です。</p>
    </article>
  </div>
</section>
