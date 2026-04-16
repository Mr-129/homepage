---
title: Scripts
description: 保管しているスクリプトを検索・絞り込みできるページ
permalink: /scripts/
layout: default
---
<section class="shell page-section">
  <header class="section-header">
    <p class="eyebrow">Archive Index</p>
    <h1>スクリプト一覧</h1>
    <p class="section-lead">保管しているスクリプトの一覧です。キーワード検索やタグで絞り込めます。</p>
  </header>

  {% comment %} 全タグを収集してソート {% endcomment %}
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

  <div class="search-toolbar">
    <div class="search-box">
      <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
      <input type="text" class="search-input" id="search-input" placeholder="タイトル、概要、タグで検索…" autocomplete="off">
    </div>
    {% if all_tags.size > 0 %}
    <div class="tag-filter" aria-label="タグで絞り込み">
      <span class="tag-filter-label">タグ:</span>
      <button class="tag-filter-btn active" data-tag="all">すべて</button>
      {% for tag in all_tags %}
        <button class="tag-filter-btn" data-tag="{{ tag }}">{{ tag }}</button>
      {% endfor %}
    </div>
    {% endif %}
  </div>

  <p class="search-result-count" id="result-count"></p>

  <div class="script-grid" id="script-grid">
    {% assign sorted_scripts = visible_scripts | sort: 'title' %}
    {% for script in sorted_scripts %}
      <article class="script-card" data-tags="{{ script.tags | join: ',' }}" data-title="{{ script.title }}" data-summary="{{ script.summary }}">
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
        {% if script.tags.size > 0 %}
        <ul class="tag-list">
          {% for tag in script.tags %}
            <li>{{ tag }}</li>
          {% endfor %}
        </ul>
        {% endif %}
      </article>
    {% endfor %}
  </div>

  <p class="no-results" id="no-results" style="display:none;">該当するスクリプトはありません。</p>
</section>

<script>
(function () {
  var searchInput = document.getElementById('search-input');
  var buttons = document.querySelectorAll('.tag-filter-btn');
  var cards = document.querySelectorAll('.script-card');
  var noResults = document.getElementById('no-results');
  var resultCount = document.getElementById('result-count');
  var totalCount = cards.length;
  var activeTag = 'all';

  // URLパラメータからタグを初期選択
  var params = new URLSearchParams(window.location.search);
  var initialTag = params.get('tag');
  if (initialTag) {
    // タグボタンが存在するか確認（タイトル検索フォールバック用）
    var found = false;
    buttons.forEach(function (btn) {
      if (btn.getAttribute('data-tag') === initialTag) {
        found = true;
        activeTag = initialTag;
        buttons.forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
      }
    });
    // タグが見つからない場合はキーワード検索にフォールバック
    if (!found) {
      searchInput.value = initialTag;
    }
  }

  function filterCards() {
    var query = (searchInput.value || '').toLowerCase().trim();
    var visibleCount = 0;

    cards.forEach(function (card) {
      var title = (card.getAttribute('data-title') || '').toLowerCase();
      var summary = (card.getAttribute('data-summary') || '').toLowerCase();
      var tags = (card.getAttribute('data-tags') || '').toLowerCase();
      var searchable = title + ' ' + summary + ' ' + tags;

      var matchesTag = (activeTag === 'all') || tags.split(',').indexOf(activeTag) !== -1;
      var matchesQuery = !query || searchable.indexOf(query) !== -1;

      if (matchesTag && matchesQuery) {
        card.style.display = '';
        visibleCount++;
      } else {
        card.style.display = 'none';
      }
    });

    noResults.style.display = visibleCount === 0 ? '' : 'none';

    if (query || activeTag !== 'all') {
      resultCount.textContent = visibleCount + ' / ' + totalCount + ' 件表示';
    } else {
      resultCount.textContent = '';
    }
  }

  searchInput.addEventListener('input', filterCards);

  buttons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      activeTag = btn.getAttribute('data-tag');
      buttons.forEach(function (b) { b.classList.remove('active'); });
      btn.classList.add('active');
      filterCards();
    });
  });

  // 初期表示時にフィルタ適用（URLパラメータ or 検索窓に値がある場合）
  filterCards();
})();
</script>
