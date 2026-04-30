/*
 * Code block toolbar: add copy / download helpers to rendered code blocks.
 *
 * This runs after the page is rendered and wraps each <pre> only once.
 * The original code content stays untouched; we only add surrounding UI.
 */
(function () {
  "use strict";

  var COPY_ICON =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
    '<rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>' +
    '<path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>';

  var CHECK_ICON =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
    '<polyline points="20 6 9 17 4 12"/></svg>';

  var DL_ICON =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
    '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>' +
    '<polyline points="7 10 12 15 17 10"/>' +
    '<line x1="12" y1="15" x2="12" y2="3"/></svg>';

  // Map syntax-highlighted language names to download file extensions.
  // Unknown languages still get a copy button, but download falls back to .txt.
  var LANG_EXT = {
    powershell: ".ps1",
    ps1: ".ps1",
    bash: ".sh",
    shell: ".sh",
    python: ".py",
    javascript: ".js",
    ruby: ".rb",
    bat: ".bat",
    cmd: ".bat",
    yaml: ".yml",
    json: ".json",
    xml: ".xml",
    html: ".html",
    css: ".css",
  };

  function detectLang(pre) {
    var code = pre.querySelector("code");
    if (!code) return "";
    var cls = code.className || "";
    var m = cls.match(/language-(\w+)/);
    return m ? m[1].toLowerCase() : "";
  }

  function getCodeText(pre) {
    var code = pre.querySelector("code");
    return (code || pre).textContent;
  }

  function createBtn(label, icon, onclick) {
    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "code-toolbar-btn";
    btn.innerHTML = icon + " " + label;
    btn.addEventListener("click", onclick);
    return btn;
  }

  function copyCode(pre, btn) {
    var text = getCodeText(pre);
    navigator.clipboard.writeText(text).then(function () {
      btn.classList.add("copied");
      btn.innerHTML = CHECK_ICON + " Copied!";
      setTimeout(function () {
        btn.classList.remove("copied");
        btn.innerHTML = COPY_ICON + " Copy";
      }, 1800);
    });
  }

  function downloadCode(pre, lang) {
    var text = getCodeText(pre);
    var ext = LANG_EXT[lang] || ".txt";
    var blob = new Blob([text], { type: "text/plain;charset=utf-8" });
    var url = URL.createObjectURL(blob);
    var a = document.createElement("a");
    a.href = url;
    a.download = "script" + ext;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  function init() {
    var pres = document.querySelectorAll(".prose pre, .content-card pre");
    pres.forEach(function (pre) {
      // Avoid wrapping the same block twice when init() is called more than once.
      if (pre.parentNode.classList.contains("code-block-wrapper")) return;

      var lang = detectLang(pre);

      var wrapper = document.createElement("div");
      wrapper.className = "code-block-wrapper";
      pre.parentNode.insertBefore(wrapper, pre);
      wrapper.appendChild(pre);

      /* Language label: mirrors the detected syntax class for quick scanning. */
      if (lang) {
        var label = document.createElement("span");
        label.className = "code-lang-label";
        label.textContent = lang;
        wrapper.appendChild(label);
      }

      /* Toolbar: buttons are created after the wrapper so they can target this block. */
      var toolbar = document.createElement("div");
      toolbar.className = "code-toolbar";

      var copyBtn = createBtn("Copy", COPY_ICON, function () {
        copyCode(pre, copyBtn);
      });
      toolbar.appendChild(copyBtn);

      if (lang && LANG_EXT[lang]) {
        var dlBtn = createBtn("Download", DL_ICON, function () {
          downloadCode(pre, lang);
        });
        toolbar.appendChild(dlBtn);
      }

      wrapper.appendChild(toolbar);
    });
  }

  // Run immediately on already-rendered pages, or wait for DOMContentLoaded on first load.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
