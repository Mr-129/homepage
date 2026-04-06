---
title: Scripts
description: 追加したスクリプトを一覧で確認するページ
permalink: /scripts/
layout: default
---
<section class="shell page-section">
  <header class="section-header">
    <p class="eyebrow">Archive Index</p>
    <h1>Scripts</h1>
    <p class="section-lead">実際に使ったスクリプトを、用途と実行条件がすぐ追える形で保管していく一覧です。Copper Fileの方針に合わせて、あとから探し直しやすい粒度で並べています。</p>
  </header>

  <div class="script-grid">
    {% assign visible_scripts = site.scripts | where_exp: 'item', 'item.published != false' %}
    {% assign sorted_scripts = visible_scripts | sort: 'title' %}
    {% for script in sorted_scripts %}
      <article class="script-card">
        <p class="eyebrow">{{ script.language | default: 'Script' }}</p>
        <h2><a href="{{ script.url | relative_url }}">{{ script.title }}</a></h2>
        <p>{{ script.summary }}</p>
        <ul class="card-meta">
          {% if script.category %}
            <li>{{ script.category }}</li>
          {% endif %}
          {% if script.environment %}
            <li>{{ script.environment }}</li>
          {% endif %}
        </ul>
      </article>
    {% endfor %}
  </div>
</section>
