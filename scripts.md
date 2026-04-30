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

  {% comment %}
    一覧ページで使う候補を先に集める。
    - visible_scripts: 公開済みの記事だけ
    - all_shelves: 表示用の本棚一覧。shelf が無い既存記事は category を棚名として使う
    - all_tags: タグ絞り込み用の一覧
  {% endcomment %}
  {% assign visible_scripts = site.scripts | where_exp: 'item', 'item.published == true' %}
  {% assign all_shelves = "" | split: "" %}
  {% assign all_tags = "" | split: "" %}
  {% for script in visible_scripts %}
    {% assign script_shelf = script.shelf | default: script.category | default: '未分類' %}
    {% unless all_shelves contains script_shelf %}
      {% assign all_shelves = all_shelves | push: script_shelf %}
    {% endunless %}
    {% for tag in script.tags %}
      {% unless all_tags contains tag %}
        {% assign all_tags = all_tags | push: tag %}
      {% endunless %}
    {% endfor %}
  {% endfor %}
  {% assign all_shelves = all_shelves | sort %}
  {% assign all_tags = all_tags | sort %}

  <div class="search-toolbar">
    <div class="search-box">
      <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
      <input type="text" class="search-input" id="search-input" placeholder="タイトル、概要、タグで検索…" autocomplete="off">
    </div>
    {% if all_shelves.size > 0 %}
    <div class="tag-filter" aria-label="本棚で絞り込み">
      <span class="tag-filter-label">本棚:</span>
      <button class="tag-filter-btn shelf-filter-btn active" data-shelf="all">すべて</button>
      {% for shelf in all_shelves %}
        <button class="tag-filter-btn shelf-filter-btn" data-shelf="{{ shelf }}">{{ shelf }}</button>
      {% endfor %}
    </div>
    {% endif %}
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
      {% comment %}
        JavaScript 側の絞り込みで使うため、棚名・タグ・タイトル・概要を data-* 属性へ埋め込む。
        shelf 未設定の記事でも動くように、ここでも shelf -> category の順で棚名を決める。
      {% endcomment %}
      {% assign script_shelf = script.shelf | default: script.category | default: '未分類' %}
      <article class="script-card" data-shelf="{{ script_shelf }}" data-tags="{{ script.tags | join: ',' }}" data-title="{{ script.title }}" data-summary="{{ script.summary }}">
        <p class="eyebrow">{{ script.language | default: 'Script' }}</p>
        <h2><a href="{{ script.url | relative_url }}">{{ script.title }}</a></h2>
        <p>{{ script.summary }}</p>
        <ul class="card-meta">
          {% if script_shelf %}
            <li>棚: {{ script_shelf }}</li>
          {% endif %}
          {% if script.category %}
            {% if script.category != script_shelf %}
            <li>分類: {{ script.category }}</li>
            {% endif %}
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
  // 棚ボタンとタグボタンは見た目が似ているので、最初に別々の集合として取得する。
  var searchInput = document.getElementById('search-input');
  var shelfButtons = document.querySelectorAll('.shelf-filter-btn');
  var tagButtons = document.querySelectorAll('.tag-filter-btn:not(.shelf-filter-btn)');
  var cards = document.querySelectorAll('.script-card');
  var noResults = document.getElementById('no-results');
  var resultCount = document.getElementById('result-count');
  var totalCount = cards.length;
  var activeShelf = 'all';
  var activeTag = 'all';

  // URLパラメータから初期状態を復元する。
  // 例: /scripts/?shelf=Windows%20運用&tag=powershell
  var params = new URLSearchParams(window.location.search);
  var initialShelf = params.get('shelf');
  var initialTag = params.get('tag');
  if (initialShelf) {
    shelfButtons.forEach(function (btn) {
      if ((btn.getAttribute('data-shelf') || '').toLowerCase() === initialShelf.toLowerCase()) {
        activeShelf = btn.getAttribute('data-shelf') || 'all';
        shelfButtons.forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
      }
    });
  }
  if (initialTag) {
    // タグボタンが存在するか確認（タイトル検索フォールバック用）
    var found = false;
    tagButtons.forEach(function (btn) {
      if (btn.getAttribute('data-tag') === initialTag) {
        found = true;
        activeTag = initialTag;
        tagButtons.forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
      }
    });
    // タグが見つからない場合はキーワード検索にフォールバック
    if (!found) {
      searchInput.value = initialTag;
    }
  }

  function filterCards() {
    // 入力欄・本棚・タグの3条件を AND で組み合わせて表示件数を決める。
    var query = (searchInput.value || '').toLowerCase().trim();
    var visibleCount = 0;

    cards.forEach(function (card) {
      // 各カードへ埋め込んだ data-* 属性だけを見れば絞り込みできるようにしている。
      var shelf = (card.getAttribute('data-shelf') || '').toLowerCase();
      var title = (card.getAttribute('data-title') || '').toLowerCase();
      var summary = (card.getAttribute('data-summary') || '').toLowerCase();
      var tags = (card.getAttribute('data-tags') || '').toLowerCase();
      var searchable = shelf + ' ' + title + ' ' + summary + ' ' + tags;

      var matchesShelf = (activeShelf === 'all') || (shelf === activeShelf.toLowerCase());
      var matchesTag = (activeTag === 'all') || tags.split(',').indexOf(activeTag) !== -1;
      var matchesQuery = !query || searchable.indexOf(query) !== -1;

      if (matchesShelf && matchesTag && matchesQuery) {
        card.style.display = '';
        visibleCount++;
      } else {
        card.style.display = 'none';
      }
    });

    noResults.style.display = visibleCount === 0 ? '' : 'none';

    if (query || activeShelf !== 'all' || activeTag !== 'all') {
      resultCount.textContent = visibleCount + ' / ' + totalCount + ' 件表示';
    } else {
      resultCount.textContent = '';
    }
  }

  searchInput.addEventListener('input', filterCards);

  // 本棚ボタンは1つだけ active にし、クリック後すぐ一覧を再計算する。
  shelfButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      activeShelf = btn.getAttribute('data-shelf') || 'all';
      shelfButtons.forEach(function (b) { b.classList.remove('active'); });
      btn.classList.add('active');
      filterCards();
    });
  });

  // タグボタンも同じ考え方で active 状態を切り替える。
  tagButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      activeTag = btn.getAttribute('data-tag');
      tagButtons.forEach(function (b) { b.classList.remove('active'); });
      btn.classList.add('active');
      filterCards();
    });
  });

  // 初期表示時にフィルタ適用（URLパラメータ or 検索窓に値がある場合）
  filterCards();
})();
</script>
