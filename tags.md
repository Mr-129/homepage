---
title: タグ一覧
description: タグ別にスクリプトを探す
permalink: /tags/
layout: default
---
<section class="shell page-section">
  <header class="section-header">
    <p class="eyebrow">Tag Index</p>
    <h1>タグ一覧</h1>
    <p class="section-lead">タグごとにスクリプトを分類しています。タグ名をクリックすると該当セクションへジャンプします。</p>
  </header>

  {% assign visible_scripts = site.scripts | where_exp: 'item', 'item.published == true' %}
  {% assign all_tags = "" | split: "" %}
  {% for script in visible_scripts %}
    {% for tag in script.tags %}
      {% unless all_tags contains tag %}
        {% assign all_tags = all_tags | push: tag %}
      {% endunless %}
    {% endfor %}
  {% endfor %}
  {% assign all_tags = all_tags | sort %}

  <nav class="tag-nav" aria-label="タグ一覧">
    {% for tag in all_tags %}
      {% assign tag_count = 0 %}
      {% for s in visible_scripts %}
        {% if s.tags contains tag %}
          {% assign tag_count = tag_count | plus: 1 %}
        {% endif %}
      {% endfor %}
      <a class="tag-nav-link" href="#tag-{{ tag }}">{{ tag }} <small>({{ tag_count }})</small></a>
    {% endfor %}
  </nav>

  {% for tag in all_tags %}
  <div class="tag-section" id="tag-{{ tag }}">
    <h2 class="tag-section-heading">{{ tag }}</h2>
    <div class="script-grid">
      {% assign sorted_scripts = visible_scripts | sort: 'title' %}
      {% for script in sorted_scripts %}
        {% if script.tags contains tag %}
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
        {% endif %}
      {% endfor %}
    </div>
  </div>
  {% endfor %}
</section>
