/* Language switch for the Vector Crisis store pages.
   Stores nothing but the chosen language, and copes with storage being blocked. */
(function () {
  var KEY = 'vc.lang';
  var root = document.documentElement;

  function read() {
    try { return localStorage.getItem(KEY); } catch (e) { return null; }
  }

  function write(lang) {
    try { localStorage.setItem(KEY, lang); } catch (e) { /* private mode, blocked cookies */ }
  }

  function detect() {
    var list = navigator.languages || [navigator.language || 'tr'];
    for (var i = 0; i < list.length; i++) {
      if (String(list[i]).toLowerCase().indexOf('tr') === 0) return 'tr';
    }
    return 'en';
  }

  function apply(lang) {
    root.setAttribute('data-lang', lang);
    root.setAttribute('lang', lang);
    var buttons = document.querySelectorAll('.lang-toggle button');
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].setAttribute('aria-pressed', String(buttons[i].dataset.setLang === lang));
    }
    var title = document.querySelector('title[data-title-' + lang + ']');
    if (title) document.title = title.getAttribute('data-title-' + lang);
  }

  apply(read() || detect());

  document.addEventListener('click', function (event) {
    var button = event.target.closest ? event.target.closest('.lang-toggle button') : null;
    if (!button) return;
    var lang = button.dataset.setLang;
    apply(lang);
    write(lang);
  });
})();
