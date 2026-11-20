/* rahimov.tr — ortak betik: tema, menü ve canlı veri araçları */
(function () {
  'use strict';
  window.__rtr = 1;
  /* ---------- Dil ---------- */
  var LANG = (document.documentElement.lang || 'tr').slice(0, 2);
  var LOC = { tr: 'tr-TR', en: 'en-US', ru: 'ru-RU', az: 'az-Latn-AZ' }[LANG] || 'tr-TR';
  var NLOC = LANG === 'az' ? 'tr-TR' : LOC;   /* az: 1.234,56 biçimi; bazı tarayıcılarda az verisi eksik */
  function pc(s) { return LANG === 'tr' ? '%' + s : s + '%'; }
  var I18N = window.RAHIMOV_I18N || {};
  function L(s) { var d = I18N[LANG]; return (d && d[s]) || s; }
  function F(s, o) { s = L(s); for (var k in o) s = s.split('{' + k + '}').join(o[k]); return s; }
  function lp(href) { return LANG === 'tr' ? href : '/' + LANG + href; }
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };

  /* ---------- Tema + menü ---------- */
  var root = document.documentElement;
  var themeBtn = $('#themeBtn');
  /* Tema: otomatik (telefon ayarı) → açık → koyu → otomatik */
  var TLAB = { auto: L('otomatik (telefon ayarı)'), light: L('açık'), dark: L('koyu') };
  function setMode(m) {
    root.setAttribute('data-mode', m);
    if (m === 'auto') root.removeAttribute('data-theme'); else root.setAttribute('data-theme', m);
    try { if (m === 'auto') localStorage.removeItem('rahimov.theme'); else localStorage.setItem('rahimov.theme', m); } catch (e) {}
    if (themeBtn) { themeBtn.setAttribute('aria-label', L('Tema: ') + TLAB[m]); themeBtn.title = L('Tema: ') + TLAB[m]; }
  }
  if (themeBtn) {
    setMode(root.getAttribute('data-mode') || 'auto');
    themeBtn.addEventListener('click', function () {
      var m = root.getAttribute('data-mode') || 'auto', next = m === 'auto' ? 'light' : m === 'light' ? 'dark' : 'auto';
      setMode(next); toast(L('Tema: ') + TLAB[next]);
    });
  }
  $$('.langsw-menu a').forEach(function (a) { a.addEventListener('click', function () { try { localStorage.setItem('rahimov.lang', a.getAttribute('data-lang')); } catch (e) {} }); });
  document.addEventListener('click', function (e) { var d = $('.langsw[open]'); if (d && !e.target.closest('.langsw')) d.open = false; });
  var menuBtn = $('#menuBtn'), navLinks = $('#navLinks');
  if (menuBtn) menuBtn.addEventListener('click', function () {
    var open = navLinks.classList.toggle('open');
    menuBtn.setAttribute('aria-expanded', String(open));
  });

  /* ---------- Yardımcılar ---------- */
  function nf(n, d) {
    if (d === undefined) d = 2;
    return new Intl.NumberFormat(NLOC, { minimumFractionDigits: d, maximumFractionDigits: d }).format(n);
  }
  function esc(s) { return String(s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
  function load(k) { try { return JSON.parse(localStorage.getItem(k)); } catch (e) { return null; } }
  function save(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) {} }
  /* iOS uygulaması (KROV) içinde mi? Uygulamayla mesajlaşma köprüsü */
  var APP = /RahimovApp/.test(navigator.userAgent);
  /* Sayfa açık kalırsa: gün değişince ya da 30 dk'dan uzun arka planda kaldıysa veriler tazelensin */
  (function () {
    var day = new Date().toDateString(), hiddenAt = 0;
    function check(force) {
      if (document.hidden) return;
      if (new Date().toDateString() !== day || force) location.reload();
    }
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) { hiddenAt = Date.now(); return; }
      check(hiddenAt && Date.now() - hiddenAt > 30 * 60000);
    });
    window.addEventListener('pageshow', function (e) { if (e.persisted) check(false); });
    setInterval(function () { check(false); }, 60000);
    window.rahimovResume = function (awaySec) { check(awaySec > 1800); };
  })();
  function appMsg(m) { try { window.webkit.messageHandlers.rahimov.postMessage(m); } catch (e) {} }
  function timed(url) {
    return new Promise(function (resolve, reject) {
      var done = false, ctl = window.AbortController ? new AbortController() : null;
      var tm = setTimeout(function () { if (!done) { done = true; if (ctl) ctl.abort(); reject(new Error(L('Zaman aşımı (15 sn)'))); } }, 15000);
      fetch(url, ctl ? { cache: 'no-cache', signal: ctl.signal } : { cache: 'no-cache' }).then(function (r) { if (!done) { done = true; clearTimeout(tm); resolve(r); } },
        function (e) { if (!done) { done = true; clearTimeout(tm); reject(e); } });
    });
  }
  var lastErr = '';
  function getJSON(url, ttl) {
    var key = 'c:' + url, now = Date.now();
    if (ttl) {
      try {
        var hit = JSON.parse(sessionStorage.getItem(key));
        if (hit && now - hit.t < ttl * 1000) return Promise.resolve(hit.d);
      } catch (e) {}
    }
    /* Truncgil dosyası 10 yıl önbellek süresiyle geliyor; dakikalık parametre eski kopyayı aşar */
    var real = url.indexOf('truncgil.com') > -1 ? url + '?_=' + Math.floor(now / 60000) : url;
    function once() {
      return timed(real).then(function (r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        return r.json();
      });
    }
    function wait(ms) { return new Promise(function (res) { setTimeout(res, ms); }); }
    /* Geçici ağ hatası ya da yarım gelen yanıt için 3 deneme */
    var lgKey = /truncgil\.com|coingecko\.com/.test(url) ? 'lg:' + url : null;
    return once().catch(function () { return wait(1200).then(once); }).catch(function () { return wait(3000).then(once); }).then(function (d) {
      try { sessionStorage.setItem(key, JSON.stringify({ t: now, d: d })); } catch (e) {}
      if (lgKey) save(lgKey, { t: now, d: d });
      return d;
    }, function (e) {
      lastErr = (url.split('/')[2] || '') + ' → ' + (e && e.message ? e.message : e);
      /* Hiç alınamazsa bu cihazdaki son başarılı veriyi göster */
      var lg = lgKey && load(lgKey);
      if (lg && lg.d && now - lg.t < 3 * 864e5) { var d = lg.d; d.__stale = lg.t; return d; }
      throw e;
    });
  }
  function fail(el, retry) {
    if (!el) return;
    if (el.tagName === 'TBODY') {   /* tabloyu silme; hata satırı göster ki sonraki yenileme tabloyu doldurabilsin */
      var n = el.parentNode.querySelectorAll('thead th').length || 3;
      el.innerHTML = '<tr><td colspan="' + n + '" style="white-space:normal"><div class="error-box">' + L('Veri şu an alınamadı. Birkaç saniye içinde yeniden denenecek.') + (lastErr ? ' <small class="muted" style="display:block;margin-top:6px">' + L('Ayrıntı: ') + esc(lastErr) + '</small>' : '') + ' <button class="btn btn-secondary btn-sm" type="button" style="margin-top:8px">' + L('Şimdi dene') + '</button></div></td></tr>';
      var bt = $('button', el); if (bt && retry) bt.addEventListener('click', retry);
      return;
    }
    el.innerHTML = '<div class="error-box">' + L('Veri şu an alınamadı. Bağlantını kontrol edip biraz sonra tekrar dene.') + (lastErr ? ' <small class="muted" style="display:block;margin-top:6px">' + L('Ayrıntı: ') + esc(lastErr) + '</small>' : '') + ' <button class="btn btn-secondary btn-sm" type="button" style="margin-left:8px">' + L('Tekrar dene') + '</button></div>';
    var b = $('button', el); if (b && retry) b.addEventListener('click', retry);
  }
  function chg(v) {
    if (typeof v !== 'number' || isNaN(v)) return '<span class="muted">—</span>';
    var cls = v > 0 ? 'up' : v < 0 ? 'down' : 'muted';
    return '<span class="' + cls + '">' + (v > 0 ? '▲ ' : v < 0 ? '▼ ' : '') + pc(nf(Math.abs(v))) + '</span>';
  }
  function pad(n) { return (n < 10 ? '0' : '') + n; }
  function stamp(src, stale) { var n = new Date(); if (stale) { var s = new Date(stale); return F('Bağlantı sorunu: {t} itibarıyla kayıtlı veri gösteriliyor · yeniden deneniyor', { t: pad(s.getHours()) + ':' + pad(s.getMinutes()) }); } return L('Kaynak verisi: ') + (src || '—') + L(' · Son kontrol: ') + pad(n.getHours()) + ':' + pad(n.getMinutes()); }
  function setText(sel, t) { var e = $(sel); if (e) { e.textContent = t; e.classList.remove('skeleton'); } }
  function setHTML(sel, t) { var e = $(sel); if (e) { e.innerHTML = t; e.classList.remove('skeleton'); } }

  var API = {
    fin: 'https://finans.truncgil.com/v4/today.json',
    fxSeries: function (base, start) { return 'https://api.frankfurter.dev/v1/' + start + '..?base=' + base + '&symbols=TRY'; },
    wx: function (c) { return 'https://api.open-meteo.com/v1/forecast?latitude=' + c.lat + '&longitude=' + c.lon + '&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,weather_code,is_day&hourly=temperature_2m,weather_code,precipitation_probability,wind_speed_10m,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,wind_speed_10m_max,uv_index_max&timezone=auto&forecast_days=7'; },
    geo: function (q) { return 'https://geocoding-api.open-meteo.com/v1/search?name=' + encodeURIComponent(q) + '&count=8&language=' + LANG; },
    quake: 'https://api.orhanaydogdu.com.tr/deprem/kandilli/live?limit=100',
    pray: function (c, d) { return 'https://api.aladhan.com/v1/timings/' + d + '?latitude=' + c.lat + '&longitude=' + c.lon + '&method=13'; },
    prayMonth: function (c, y, m) { return 'https://api.aladhan.com/v1/calendar/' + y + '/' + m + '?latitude=' + c.lat + '&longitude=' + c.lon + '&method=13'; },
    crypto: 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,tether,binancecoin,solana,ripple,dogecoin,cardano,tron,avalanche-2&vs_currencies=usd,try&include_24hr_change=true',
    rev: function (la, lo) { return 'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=' + la + '&longitude=' + lo + '&localityLanguage=' + LANG; },
    hol: function (y) { return 'https://date.nager.at/api/v3/PublicHolidays/' + y + '/TR'; }
  };

  /* ---------- Şehir seçimi (hava + namaz ortak) ---------- */
  var DEFAULT_CITY = { name: L('İstanbul'), lat: 41.0082, lon: 28.9784 };
  function getCity() { var c = load('rahimov.city'); return c && c.lat ? c : DEFAULT_CITY; }
  function initCity(onChange) {
    var input = $('#cityInput'), box = $('#citySuggest'), geoBtn = $('#geoBtn'), timer;
    function pick(c) { save('rahimov.city', c); appMsg({ type: 'city', city: c }); if (input) input.value = ''; if (box) box.hidden = true; onChange(c); }
    $$('.city-chip').forEach(function (b) {
      b.addEventListener('click', function () { pick({ name: b.textContent.trim(), lat: +b.dataset.lat, lon: +b.dataset.lon }); });
    });
    if (input) {
      input.addEventListener('input', function () {
        clearTimeout(timer);
        var q = input.value.trim();
        if (q.length < 2) { box.hidden = true; return; }
        timer = setTimeout(function () {
          getJSON(API.geo(q), 3600).then(function (j) {
            var res = (j.results || []).sort(function (a, b) { return (b.country_code === 'TR') - (a.country_code === 'TR'); }).slice(0, 6);
            if (!res.length) { box.innerHTML = '<button type="button" disabled>' + L('Sonuç bulunamadı') + '</button>'; box.hidden = false; return; }
            box.innerHTML = res.map(function (r, i) {
              return '<button type="button" data-i="' + i + '">' + esc(r.name) + ' <small>' + esc([r.admin1, r.country].filter(Boolean).join(', ')) + '</small></button>';
            }).join('');
            box.hidden = false;
            $$('button[data-i]', box).forEach(function (b) {
              b.addEventListener('click', function () { var r = res[+b.dataset.i]; pick({ name: r.name, lat: r.latitude, lon: r.longitude }); });
            });
          }).catch(function () { box.hidden = true; });
        }, 300);
      });
      document.addEventListener('click', function (e) { if (!e.target.closest('.citybar')) box.hidden = true; });
    }
    function locate(done, fail2) {
      navigator.geolocation.getCurrentPosition(function (p) {
        var la = +p.coords.latitude.toFixed(3), lo = +p.coords.longitude.toFixed(3);
        getJSON(API.rev(la, lo), 86400).then(function (j) { return j.city || j.locality || j.principalSubdivision || L('Konumun'); }, function () { return L('Konumun'); })
          .then(function (n) { pick({ name: n, lat: la, lon: lo }); if (done) done(); });
      }, function () { if (fail2) fail2(); }, { timeout: 10000, maximumAge: 3600000 });
    }
    if (geoBtn) {
      if (!navigator.geolocation) geoBtn.hidden = true;
      geoBtn.addEventListener('click', function () {
        if (APP) { appMsg({ type: 'locate' }); return; }
        geoBtn.disabled = true;
        locate(function () { geoBtn.disabled = false; }, function () { geoBtn.disabled = false; geoBtn.textContent = L('Konum izni verilmedi'); });
      });
    }
    onChange(getCity());
    /* İlk ziyarette bir kez konum iste; reddedilirse İstanbul kalır */
    if (!APP && !load('rahimov.city') && !load('rahimov.geoAsked') && navigator.geolocation) {
      save('rahimov.geoAsked', 1);
      locate();
    }
  }

  /* ---------- Hava durumu kodları ---------- */
  var CLOUD = '<path class="c" d="M7 18.5h10.2a4.3 4.3 0 0 0 .5-8.6A6.3 6.3 0 0 0 5.6 11.4 3.6 3.6 0 0 0 7 18.5z"/>';
  var CLOUD_HI = '<path class="c" d="M7 14.5h10.2a4.1 4.1 0 0 0 .5-8.2A6 6 0 0 0 5.8 7.8 3.4 3.4 0 0 0 7 14.5z"/>';
  var WX_ICON = {
    sun: '<svg viewBox="0 0 24 24"><g class="s"><circle cx="12" cy="12" r="4.6"/><path d="M12 2.5v2.2M12 19.3v2.2M5.3 5.3l1.5 1.5M17.2 17.2l1.5 1.5M2.5 12h2.2M19.3 12h2.2M5.3 18.7l1.5-1.5M17.2 6.8l1.5-1.5"/></g></svg>',
    moon: '<svg viewBox="0 0 24 24"><path class="m" d="M19.5 14.6A7.8 7.8 0 1 1 9.4 4.5a6.3 6.3 0 0 0 10.1 10.1z"/><path class="st" d="M17 4.2l.5 1.2 1.2.5-1.2.5-.5 1.2-.5-1.2-1.2-.5 1.2-.5z"/></svg>',
    partly: '<svg viewBox="0 0 24 24"><g class="s"><circle cx="8.5" cy="8.5" r="3.4"/><path d="M8.5 2.3v1.3M2.3 8.5h1.3M4.1 4.1l.9.9M12.9 4.1l-.9.9"/></g>' + CLOUD.replace('M7 18.5', 'M8.5 19.5').replace('a4.3 4.3 0 0 0 .5-8.6A6.3 6.3 0 0 0 5.6 11.4 3.6 3.6 0 0 0 7 18.5z', 'a4 4 0 0 0 .5-8 5.8 5.8 0 0 0-11 1.6 3.3 3.3 0 0 0 .3 6.4z') + '</svg>',
    partlyNight: '<svg viewBox="0 0 24 24"><path class="m" d="M13.2 8.6A5.4 5.4 0 1 1 6.2 2.6a4.4 4.4 0 0 0 7 6z"/><path class="c" d="M8.5 19.5h9.2a4 4 0 0 0 .5-8 5.8 5.8 0 0 0-11 1.6 3.3 3.3 0 0 0 .3 6.4z"/></svg>',
    cloud: '<svg viewBox="0 0 24 24"><path class="c2" d="M13 9.5h6.5a3 3 0 0 0 .3-6 4.3 4.3 0 0 0-8.1 1.1"/>' + CLOUD + '</svg>',
    fog: '<svg viewBox="0 0 24 24">' + CLOUD_HI + '<path class="f" d="M4 17.5h16M6 21h12"/></svg>',
    rain: '<svg viewBox="0 0 24 24">' + CLOUD_HI + '<path class="r" d="M8.5 17.5l-1.2 3.2M12.5 17.5l-1.2 3.2M16.5 17.5l-1.2 3.2"/></svg>',
    snow: '<svg viewBox="0 0 24 24">' + CLOUD_HI + '<g class="sn"><circle cx="8" cy="18.5" r="1.1"/><circle cx="12" cy="20.5" r="1.1"/><circle cx="16" cy="18.5" r="1.1"/><circle cx="10" cy="22.3" r=".9"/><circle cx="14" cy="22.3" r=".9"/></g></svg>',
    storm: '<svg viewBox="0 0 24 24">' + CLOUD_HI.replace('class="c"', 'class="c dk"') + '<path class="b" d="M12.8 13.2l-3.3 4.8h3.4l-2.2 4.6 5.4-6.4h-3.4l2-3z"/></svg>',
    wind: '<svg viewBox="0 0 24 24"><path class="w" d="M3 9h11.5a3 3 0 1 0-3-3M3 13.5h15.5a3 3 0 1 1-3 3M3 18h7"/></svg>'
  };
  /* Bilgi satırları için tek renk çizgi ikonları */
  var MI = {
    hum: '<svg viewBox="0 0 24 24"><path d="M12 3s6 6.4 6 10.6A6 6 0 0 1 6 13.6C6 9.4 12 3 12 3z"/></svg>',
    wind: '<svg viewBox="0 0 24 24"><path d="M3 9h11.5a3 3 0 1 0-3-3M3 13.5h15.5a3 3 0 1 1-3 3M3 18h7"/></svg>',
    rain: '<svg viewBox="0 0 24 24"><path d="M3 12a9 9 0 0 1 18 0zM12 12v7a2 2 0 0 0 4 0"/></svg>',
    rise: '<svg viewBox="0 0 24 24"><path d="M7 16a5 5 0 0 1 10 0M2 19h20M12 4v5M9.5 6.5L12 4l2.5 2.5M4.5 11l1.4 1.4M19.5 11l-1.4 1.4"/></svg>',
    set: '<svg viewBox="0 0 24 24"><path d="M7 16a5 5 0 0 1 10 0M2 19h20M12 4v5M9.5 6.5L12 9l2.5-2.5M4.5 11l1.4 1.4M19.5 11l-1.4 1.4"/></svg>',
    temp: '<svg viewBox="0 0 24 24"><path d="M10 13.5V5a2 2 0 0 1 4 0v8.5a4 4 0 1 1-4 0zM12 9v7"/></svg>',
    arrow: '<svg viewBox="0 0 24 24"><path d="M12 4v16M6 14l6 6 6-6"/></svg>',
    drop: '<svg viewBox="0 0 24 24"><path d="M12 3s6 6.4 6 10.6A6 6 0 0 1 6 13.6C6 9.4 12 3 12 3z"/></svg>',
    uv: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>'
  };
  function mi(n, st) { return '<span class="mi"' + (st ? ' style="' + st + '"' : '') + ' aria-hidden="true">' + MI[n] + '</span>'; }
  /* Gökyüzü teması: hava kartı ve saatlik kutuların arka planı */
  function sky(code, isDay) {
    if (code >= 95) return 'storm';
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return 'snow';
    if (code >= 51) return isDay ? 'rain' : 'rain-n';
    if (code === 45 || code === 48) return 'fog';
    if (code === 3) return isDay ? 'cloud' : 'cloud-n';
    return isDay ? (code === 2 ? 'partly' : 'clear') : 'night';
  }
  function wx(code, isDay) {
    var d = isDay === undefined || isDay ? 1 : 0;
    if (code === 0) return [L('Açık'), d ? 'sun' : 'moon'];
    if (code === 1) return [L('Az bulutlu'), d ? 'partly' : 'partlyNight'];
    if (code === 2) return [L('Parçalı bulutlu'), d ? 'partly' : 'partlyNight'];
    if (code === 3) return [L('Kapalı'), 'cloud'];
    if (code === 45 || code === 48) return [L('Sisli'), 'fog'];
    if (code >= 51 && code <= 55) return [L('Çisenti'), 'rain'];
    if (code === 56 || code === 57) return [L('Dondurucu çisenti'), 'rain'];
    if (code === 61) return [L('Hafif yağmur'), 'rain'];
    if (code === 63) return [L('Yağmur'), 'rain'];
    if (code === 65) return [L('Kuvvetli yağmur'), 'rain'];
    if (code === 66 || code === 67) return [L('Dondurucu yağmur'), 'rain'];
    if (code === 71) return [L('Hafif kar'), 'snow'];
    if (code === 73) return [L('Kar'), 'snow'];
    if (code === 75) return [L('Yoğun kar'), 'snow'];
    if (code === 77) return [L('Kar taneleri'), 'snow'];
    if (code >= 80 && code <= 82) return [L('Sağanak yağış'), 'rain'];
    if (code === 85 || code === 86) return [L('Kar sağanağı'), 'snow'];
    if (code === 95) return [L('Gök gürültülü fırtına'), 'storm'];
    if (code === 96 || code === 99) return [L('Dolulu fırtına'), 'storm'];
    return [L('—'), 'cloud'];
  }
  function wxIcon(name) { return '<span class="wx-ic" aria-hidden="true">' + WX_ICON[name] + '</span>'; }
  function cap(s) { return s.charAt(0).toLocaleUpperCase(LOC) + s.slice(1); }
  var DAYS = LANG === 'tr' ? ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'] : LANG === 'az' ? ['Bazar', 'Bazar ertəsi', 'Çərşənbə axşamı', 'Çərşənbə', 'Cümə axşamı', 'Cümə', 'Şənbə'] : [0, 1, 2, 3, 4, 5, 6].map(function (i) { var w = new Date(2026, 10, 15 + i).toLocaleDateString(LOC, { weekday: 'long' }); return LANG === 'ru' ? w : cap(w); });
  var MONTHS = LANG === 'tr' ? ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'] : LANG === 'az' ? ['yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', 'iyul', 'avqust', 'sentyabr', 'oktyabr', 'noyabr', 'dekabr'] : [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(function (i) { return cap(new Date(2026, i, 1).toLocaleDateString(LOC, { month: 'long' })); });
  function dm(d) { return LANG === 'tr' || LANG === 'az' ? d.getDate() + ' ' + MONTHS[d.getMonth()] : d.toLocaleDateString(LOC, { day: 'numeric', month: 'long' }); }
  function holName(h) { return LANG === 'tr' ? h.localName : LANG === 'en' ? h.name : L('tatil:' + h.localName) !== 'tatil:' + h.localName ? L('tatil:' + h.localName) : h.name; }
  function trDate(d) { return LANG === 'tr' || LANG === 'az' ? d.getDate() + ' ' + MONTHS[d.getMonth()] + ' ' + d.getFullYear() : d.toLocaleDateString(LOC, { day: 'numeric', month: 'long', year: 'numeric' }); }

  /* ---------- Üst şerit (her sayfada) ---------- */
  function ticker() {
    var el = $('#ticker'); if (!el) return;
    if (!ticker.t) ticker.t = setInterval(ticker, 300000);   /* 5 dk'da bir */
    getJSON(API.fin, 240).then(function (j) {
      var items = [['USD', L('Dolar'), 4], ['EUR', L('Euro'), 4], ['GBP', L('Sterlin'), 4], ['CHF', L('Frank'), 4], ['GRA', L('Gram altın'), 2], ['CEYREKALTIN', L('Çeyrek altın'), 2], ['YARIMALTIN', L('Yarım altın'), 2], ['GUMUS', L('Gümüş'), 2]];
      var one = items.filter(function (i) { return j[i[0]] && typeof j[i[0]].Selling === 'number'; }).map(function (i) {
        var x = j[i[0]];
        return '<a class="tick num" href="' + lp(i[0].length === 3 && i[0] !== 'GRA' ? '/doviz/' : '/altin/') + '"><span>' + i[1] + '</span><b>' + nf(x.Selling, i[2]) + ' ₺</b>' + chg(x.Change) + '</a>';
      }).join('');
      if (!one) { el.parentNode.hidden = true; return; }
      var g = '<div class="mgroup">' + one + one + '</div>';
      el.innerHTML = '<div class="marquee-track">' + g + g.replace('class="mgroup"', 'class="mgroup" aria-hidden="true"').replace(/href=/g, 'tabindex="-1" href=') + '</div>';
      var w = $('.mgroup', el).offsetWidth || 2000;
      el.style.setProperty('--dur', Math.max(30, Math.round(w / 55)) + 's');   /* ~55 px/sn */
    }).catch(function () { el.parentNode.hidden = true; });
  }

  /* ---------- Ana sayfa ---------- */
  function home() {
    function greet() {
      var now0 = new Date(), h0 = now0.getHours();
      setText('#greet', h0 >= 5 && h0 < 11 ? L('Günaydın.') : h0 < 17 && h0 >= 11 ? L('İyi günler.') : h0 >= 17 && h0 < 22 ? L('İyi akşamlar.') : L('İyi geceler.'));
      setText('#today-date', trDate(now0) + ', ' + DAYS[now0.getDay()]);
    }
    greet(); setInterval(greet, 60000);

    function fin() {
      getJSON(API.fin, 110).then(function (j) {
        var u = j.USD;
        if (u) { setText('#t-usd', nf(u.Selling, 4) + ' ₺'); setHTML('#t-usd-sub', chg(u.Change) + ' <span class="muted">· ' + L('alış') + ' ' + nf(u.Buying, 4) + ' ₺</span>'); }
        [['EUR', 4], ['GBP', 4], ['GRA', 2], ['CEYREKALTIN', 2]].forEach(function (i) {
          var x = j[i[0]]; if (!x || typeof x.Selling !== 'number') return;
          setText('#c-' + i[0], nf(x.Selling, i[1]) + ' ₺');
          setHTML('#c-' + i[0] + '-c', chg(x.Change));
        });
        setText('#fx-time', stamp(j.Update_Date, j.__stale));
      }).catch(function () { setText('#t-usd', '—'); setText('#t-usd-sub', L('Veri alınamadı')); });
    }
    function spark() {
      var svg = $('#spark'); if (!svg) return;
      var d = new Date(); d.setDate(d.getDate() - 34);
      var start = d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
      getJSON(API.fxSeries('USD', start), 3600).then(function (j) {
        var keys = Object.keys(j.rates || {}).sort(), v = keys.map(function (k) { return j.rates[k].TRY; }).filter(Boolean);
        if (v.length < 2) return;
        var mn = Math.min.apply(null, v), mx = Math.max.apply(null, v), sp = (mx - mn) || 1;
        var pts = v.map(function (y, i) { return [i / (v.length - 1) * 300, 64 - (y - mn) / sp * 56]; });
        var line = pts.map(function (p, i) { return (i ? 'L' : 'M') + p[0].toFixed(1) + ' ' + p[1].toFixed(1); }).join('');
        svg.innerHTML = '<path class="area" d="' + line + 'L300 70L0 70Z"/><path class="line" d="' + line + '"/>';
        var ch = (v[v.length - 1] / v[0] - 1) * 100;
        setText('#spark-range', nf(mn, 2) + ' – ' + nf(mx, 2) + ' ₺ · ' + (ch >= 0 ? '+' : '−') + nf(Math.abs(ch), 1) + '%');
      }).catch(function () {});
    }
    function weather(c) {
      getJSON(API.wx(c), 900).then(function (j) {
        var w = wx(j.current.weather_code, j.current.is_day);
        setHTML('#wx-ic', wxIcon(w[1]));
        setText('#t-wx', Math.round(j.current.temperature_2m) + '°');
        setText('#t-wx-sub', w[0] + ' · ' + L('en düşük') + ' ' + Math.round(j.daily.temperature_2m_min[0]) + '°, ' + L('en yüksek') + ' ' + Math.round(j.daily.temperature_2m_max[0]) + '°');
        var H = j.hourly, cur = String(j.current.time || '').slice(0, 13), i0 = 0;
        for (var i = 0; i < H.time.length; i++) { if (H.time[i].slice(0, 13) >= cur) { i0 = i; break; } }
        var out = '';
        for (var k = i0 + 1; k < Math.min(i0 + 7, H.time.length); k++) {
          var hh = +H.time[k].slice(11, 13), ww = wx(H.weather_code[k], hh >= 7 && hh < 18 ? 1 : 0);
          out += '<div><small>' + H.time[k].slice(11, 16) + '</small>' + wxIcon(ww[1]) + Math.round(H.temperature_2m[k]) + '°</div>';
        }
        setHTML('#wx-strip', out);
      }).catch(function () { setText('#t-wx', '—'); setText('#t-wx-sub', L('Veri alınamadı')); });
    }
    var prayTick, PHASE = ['yatsi', 'imsak', 'gunes', 'ogle', 'ikindi', 'aksam'];
    function dstr(d) { return pad(d.getDate()) + '-' + pad(d.getMonth() + 1) + '-' + d.getFullYear(); }
    function prayer(c) {
      clearInterval(prayTick);
      var today = new Date(), tom = new Date(); tom.setDate(tom.getDate() + 1);
      Promise.all([getJSON(API.pray(c, dstr(today)), 3600), getJSON(API.pray(c, dstr(tom)), 3600).catch(function () { return null; })]).then(function (r) {
        var t = r[0].data.timings, t2 = r[1] && r[1].data.timings;
        function mins(s) { var a = s.slice(0, 5).split(':'); return +a[0] * 60 + +a[1]; }
        function draw() {
          var n = new Date(), sec = n.getHours() * 3600 + n.getMinutes() * 60 + n.getSeconds(), next = -1, target;
          PR.forEach(function (p, i) { if (next < 0 && mins(t[p[0]]) * 60 > sec) next = i; });
          if (next >= 0) target = mins(t[PR[next][0]]) * 60;
          else if (t2) { next = 0; target = 86400 + mins(t2.Imsak) * 60; }
          else { setText('#pray-count', '—'); return; }
          var left = target - sec;
          setText('#pray-next-name', F('{p} vaktine kalan', { p: L(PR[next][1]) }));
          setText('#pray-count', pad(Math.floor(left / 3600)) + ':' + pad(Math.floor(left % 3600 / 60)) + ':' + pad(left % 60));
          var tile = $('#pray-tile'); if (tile) tile.setAttribute('data-phase', PHASE[next]);
          setHTML('#pray-mini', PR.map(function (p, i) { return '<div' + (i === next ? ' class="is-next"' : '') + '>' + L(p[1]) + '<b>' + t[p[0]].slice(0, 5) + '</b></div>'; }).join(''));
        }
        draw(); prayTick = setInterval(draw, 1000);
      }).catch(function () { setText('#pray-count', '—'); setText('#pray-next-name', L('Vakitler alınamadı')); });
    }
    function ago(s) {
      var d = new Date(String(s).replace(' ', 'T')), m = Math.round((Date.now() - d) / 60000);
      if (isNaN(m)) return '';
      return m < 1 ? L('az önce') : m < 60 ? F('{n} dk önce', { n: m }) : m < 1440 ? F('{n} sa önce', { n: Math.floor(m / 60) }) : F('{n} gün önce', { n: Math.floor(m / 1440) });
    }
    function quakes() {
      getJSON(API.quake, 110).then(function (j) {
        var L = j.result || [], q = L[0]; if (!q) return;
        var m = +q.mag, el = $('#qk-mag');
        el.textContent = nf(m, 1); el.className = 'qk-mag ' + (m >= 5 ? 'm5' : m >= 4 ? 'm4' : m >= 3 ? 'm3' : '');
        setText('#qk-place', q.title || '');
        setText('#qk-time', ago(q.date_time) + ' · ' + F('{n} km derinlik', { n: nf(+q.depth, 1) }));
        setHTML('#qk-list', L.slice(1, 4).map(function (e) { return '<li><span>' + esc(e.title || '') + '</span><b>' + nf(+e.mag, 1) + '</b></li>'; }).join(''));
        var hq = $('#home-quakes'); if (hq) hq.innerHTML = quakeRows(L.slice(0, 5));
      }).catch(function () { setText('#qk-place', L('Veri alınamadı')); var hq = $('#home-quakes'); if (hq) fail(hq, quakes); });
    }
    function coin() {
      getJSON(API.crypto, 110).then(function (j) {
        var b = j.bitcoin; if (!b) return;
        setText('#btc', nf(b.try, 0) + ' ₺');
        setHTML('#btc-sub', chg(b.usd_24h_change) + ' <span class="muted">· ' + nf(b.usd, 0) + ' $</span>');
      }).catch(function () { setText('#btc', '—'); });
    }
    function holiday() {
      var y = new Date().getFullYear();
      Promise.all([getJSON(API.hol(y), 86400), getJSON(API.hol(y + 1), 86400).catch(function () { return []; })]).then(function (r) {
        var today = new Date(); today.setHours(0, 0, 0, 0);
        var nx = r[0].concat(r[1]).map(function (h) { var d = new Date(h.date + 'T00:00:00'); return { d: d, name: holName(h), left: Math.round((d - today) / 864e5) }; })
          .filter(function (h) { return h.left >= 0; })[0];
        if (!nx) return;
        setText('#hol-left', nx.left === 0 ? L('Bugün') : F('{n} gün', { n: nx.left }));
        setText('#hol-name', nx.name + ' · ' + dm(nx.d));
      }).catch(function () { setText('#hol-left', '—'); });
    }
    initCity(function (c) {
      ['#city-name', '#wx-city', '#pray-city'].forEach(function (s) { setText(s, c.name); });
      var cp = $('#citypop'); if (cp) cp.open = false;
      weather(c); prayer(c);
    });
    fin(); spark(); quakes(); coin(); holiday();
    setInterval(function () { fin(); quakes(); coin(); }, 120000);
    setInterval(function () { weather(getCity()); }, 900000);
  }

  /* ---------- Döviz ---------- */
  var CNAME = { TRY: 'Türk Lirası', USD: 'ABD Doları', EUR: 'Euro', GBP: 'İngiliz Sterlini', CHF: 'İsviçre Frangı', CAD: 'Kanada Doları', RUB: 'Rus Rublesi', AED: 'BAE Dirhemi', AUD: 'Avustralya Doları', DKK: 'Danimarka Kronu', SEK: 'İsveç Kronu', NOK: 'Norveç Kronu', JPY: 'Japon Yeni', KWD: 'Kuveyt Dinarı', ZAR: 'Güney Afrika Randı', BHD: 'Bahreyn Dinarı', LYD: 'Libya Dinarı', SAR: 'Suudi Riyali', IQD: 'Irak Dinarı', ILS: 'İsrail Şekeli', INR: 'Hindistan Rupisi', MXN: 'Meksika Pesosu', HUF: 'Macar Forinti', NZD: 'Yeni Zelanda Doları', BRL: 'Brezilya Reali', IDR: 'Endonezya Rupisi', CZK: 'Çek Korunası', PLN: 'Polonya Zlotisi', RON: 'Rumen Leyi', CNY: 'Çin Yuanı', ARS: 'Arjantin Pesosu', ALL: 'Arnavut Leki', AZN: 'Azerbaycan Manatı', BAM: 'Bosna-Hersek Markı', CLP: 'Şili Pesosu', COP: 'Kolombiya Pesosu', CRC: 'Kosta Rika Kolonu', DZD: 'Cezayir Dinarı', EGP: 'Mısır Lirası', HKD: 'Hong Kong Doları', ISK: 'İzlanda Kronu', KRW: 'Güney Kore Wonu', KZT: 'Kazakistan Tengesi', LBP: 'Lübnan Lirası', LKR: 'Sri Lanka Rupisi', MAD: 'Fas Dirhemi', MDL: 'Moldova Leyi', MKD: 'Makedon Dinarı', MYR: 'Malezya Ringgiti', OMR: 'Umman Riyali', PEN: 'Peru Solü', PHP: 'Filipin Pesosu', PKR: 'Pakistan Rupisi', QAR: 'Katar Riyali', RSD: 'Sırp Dinarı', SGD: 'Singapur Doları', SYP: 'Suriye Lirası', THB: 'Tayland Bahtı', TWD: 'Tayvan Doları', UAH: 'Ukrayna Grivnası', UYU: 'Uruguay Pesosu', GEL: 'Gürcü Larisi', TND: 'Tunus Dinarı', BGN: 'Bulgar Levası', VND: 'Vietnam Dongu' };
  if (LANG !== 'tr') {
    var AZC = { USD: 'ABŞ dolları', EUR: 'Avro', GBP: 'Britaniya funtu', CHF: 'İsveçrə frankı', SAR: 'Səudiyyə riyalı', AED: 'BƏƏ dirhəmi', AZN: 'Azərbaycan manatı', RUB: 'Rusiya rublu', JPY: 'Yaponiya yeni', CNY: 'Çin yuanı', CAD: 'Kanada dolları', AUD: 'Avstraliya dolları', KWD: 'Küveyt dinarı', QAR: 'Qətər riyalı', GEL: 'Gürcüstan larisi', BGN: 'Bolqarıstan levi', RON: 'Rumıniya leyi', PLN: 'Polşa zlotısı', SEK: 'İsveç kronu', NOK: 'Norveç kronu', DKK: 'Danimarka kronu', TRY: 'Türk lirəsi', KZT: 'Qazaxıstan tengesi', UAH: 'Ukrayna qrivnası', IQD: 'İraq dinarı', ILS: 'İsrail şekeli', EGP: 'Misir funtu', INR: 'Hindistan rupisi' };
    try { var DN = new Intl.DisplayNames([LOC, 'en'], { type: 'currency' }); Object.keys(CNAME).forEach(function (c) { var n = DN.of(c); if (n && n !== c) CNAME[c] = n.charAt(0).toUpperCase() + n.slice(1); }); } catch (e) {}
    if (LANG === 'az') Object.keys(AZC).forEach(function (c) { CNAME[c] = AZC[c]; });
  }
  var FX_FIRST = ['USD', 'EUR', 'GBP', 'CHF', 'SAR', 'AED', 'AZN', 'RUB', 'JPY', 'CNY', 'CAD', 'AUD', 'KWD', 'QAR', 'GEL', 'BGN', 'RON', 'PLN', 'SEK', 'NOK', 'DKK'];
  var TRMON = LANG === 'tr' ? ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'] : LANG === 'az' ? ['yan', 'fev', 'mar', 'apr', 'may', 'iyn', 'iyl', 'avq', 'sen', 'okt', 'noy', 'dek'] : [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(function (i) { return new Date(2026, i, 1).toLocaleDateString(LOC, { month: 'short' }).replace('.', ''); });
  function flag(c) { return 'https://flagcdn.com/' + (c === 'EUR' ? 'eu' : c.slice(0, 2).toLowerCase()) + '.svg'; }
  function dec(v) { return v >= 100 ? 2 : v >= 1 ? 4 : 6; }
  function parseAmt(s) {
    s = String(s).replace(/\s/g, '');
    if (LANG === 'en') return parseFloat(s.replace(/,/g, ''));
    if (s.indexOf(',') > -1) s = s.replace(/\./g, '').replace(',', '.');
    else if ((s.match(/\./g) || []).length > 1) s = s.replace(/\./g, '');
    return parseFloat(s);
  }
  function sparkPath(v, w, h, pad) {
    var mn = Math.min.apply(null, v), mx = Math.max.apply(null, v), sp = (mx - mn) || 1;
    return v.map(function (y, i) { return (i ? 'L' : 'M') + (i / (v.length - 1) * w).toFixed(1) + ' ' + (h - pad - (y - mn) / sp * (h - pad * 2)).toFixed(1); }).join('');
  }
  /* Frankfurter (merkez bankası) geçmişi olan para birimleri */
  var FRANK = ['USD', 'EUR', 'GBP', 'CHF', 'JPY', 'AUD', 'CAD', 'CNY', 'DKK', 'SEK', 'NOK', 'PLN', 'RON', 'BGN', 'CZK', 'HUF', 'ISK', 'NZD', 'SGD', 'HKD', 'KRW', 'INR', 'IDR', 'ILS', 'MXN', 'MYR', 'PHP', 'THB', 'ZAR', 'BRL'];
  var FAV_MAX = 4, FAV_DEF = ['USD', 'EUR', 'GBP', 'CHF'];
  function fxHistory(codes) {
    codes = codes.filter(function (c) { return FRANK.indexOf(c) > -1; });
    if (!codes.length) return Promise.resolve({ days: [] });
    var d = new Date(); d.setDate(d.getDate() - 372);
    var start = d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
    return getJSON('https://api.frankfurter.dev/v1/' + start + '..?base=TRY&symbols=' + codes.slice().sort().join(','), 21600).then(function (j) {
      var days = Object.keys(j.rates || {}).sort(), out = { days: days };
      codes.forEach(function (c) { out[c] = days.map(function (k) { var r = j.rates[k][c]; return r ? 1 / r : null; }); });
      return out;
    });
  }
  var toastT;
  function toast(msg) {
    var el = $('#toast');
    if (!el) { el = document.createElement('div'); el.id = 'toast'; el.className = 'toast'; el.setAttribute('role', 'status'); document.body.appendChild(el); }
    el.textContent = msg; el.classList.add('show');
    clearTimeout(toastT); toastT = setTimeout(function () { el.classList.remove('show'); }, 3500);
  }
  /* Merkez bankası listesinde olmayan kurlar (AZN, SAR, RUB…) için günlük arşiv: jsDelivr üzerindeki açık döviz verisi.
     Geçmiş günler değişmediği için her gün bu cihazda kalıcı saklanır. */
  var FAW = 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@';
  function ymd(d) { return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()); }
  function fawDay(ds) {
    var k = 'faw:' + ds, c = load(k); if (c) return Promise.resolve(c);
    return timed(FAW + ds + '/v1/currencies/try.min.json').then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); }).then(function (j) {
      var o = {}; Object.keys(CNAME).forEach(function (c) { var v = j.try && j.try[c.toLowerCase()]; if (v) o[c] = +(1 / v).toPrecision(6); });
      save(k, o); return o;
    });
  }
  function fawSeries(code, days) {
    var step = days > 200 ? 14 : days > 60 ? 5 : 2, dates = [], y = new Date(); y.setDate(y.getDate() - 1);
    for (var i = 0; i <= days; i++) { var d = new Date(y); d.setDate(y.getDate() - i); if (i === 0 || Math.floor(d.getTime() / 864e5) % step === 0) dates.push(ymd(d)); }
    dates.reverse();
    return Promise.all(dates.map(function (ds) { return fawDay(ds).then(function (o) { return o[code] ? [ds, o[code]] : null; }, function () { return null; }); }))
      .then(function (a) { return a.filter(Boolean); });
  }
  function short(c) { return ({ USD: L('Dolar'), EUR: L('Euro'), GBP: L('Sterlin'), CHF: L('Frank') })[c] || CNAME[c] || c; }
  function doviz() {
    var R = { TRY: { b: 1, s: 1, c: 0 } }, mode = 'mid', hist = { days: [] }, chDays = 90, editing = false, sort = null, dir = 1, fser = {}, fbusy = {};
    var FAV = load('rahimov.fxfav'); if (!FAV || !FAV.length) FAV = FAV_DEF.slice();
    var chCur = FAV[0] || 'USD';
    var amt = $('#fx-amt'), from = $('#fx-from'), to = $('#fx-to'), res = $('#fx-res'), body = $('#fx-body'), search = $('#fx-search');
    function rate(c) { var x = R[c]; if (!x) return NaN; return mode === 'sell' ? x.s : mode === 'buy' ? x.b : (x.b + x.s) / 2; }
    function convert() {
      $('#fx-from-flag').src = flag(from.value); $('#fx-to-flag').src = flag(to.value);
      setText('#fx-from-code', from.value); setText('#fx-to-code', to.value); setText('#fx-from-name', CNAME[from.value] || from.value); setText('#fx-to-name', CNAME[to.value] || to.value);
      var a = parseAmt(amt.value), r = rate(from.value) / rate(to.value);
      if (isNaN(a) || isNaN(r)) { res.textContent = '—'; return; }
      var v = a * r;
      res.textContent = nf(v, v >= 1 ? 2 : 4);
      res.style.fontSize = res.textContent.length > 12 ? '30px' : '';
      setText('#cv-rate', '1 ' + from.value + ' = ' + nf(r, dec(r)) + ' ' + to.value);
      $$('#fx-body tr[data-c]').forEach(function (tr) { tr.classList.toggle('is-sel', tr.dataset.c === from.value); });
    }
    function codesAll() { return FX_FIRST.filter(function (c) { return R[c]; }).concat(Object.keys(R).filter(function (c) { return c !== 'TRY' && FX_FIRST.indexOf(c) < 0; }).sort()); }
    function options() {
      var html = ['TRY'].concat(codesAll()).map(function (c) { return '<option value="' + c + '">' + c + ' · ' + (CNAME[c] || c) + '</option>'; }).join('');
      var f = from.value || 'USD', t = to.value || 'TRY';
      from.innerHTML = html; to.innerHTML = html; from.value = f; to.value = t;
    }
    function setFrom(c) { from.value = c; if (to.value === c) to.value = 'TRY'; convert(); $('#conv').scrollIntoView({ behavior: 'smooth', block: 'start' }); }

    function needF(code, days, then) {
      var k = code + '|' + days; if (fser[k] || fbusy[k] || FRANK.indexOf(code) > -1) return;
      fbusy[k] = 1;
      fawSeries(code, days).then(function (p) { fser[k] = p; delete fbusy[k]; if (then) then(); }, function () { delete fbusy[k]; });
    }
    /* ---- favoriler ---- */
    function saveFav() { save('rahimov.fxfav', FAV); }
    function toggleFav(c) {
      var i = FAV.indexOf(c);
      if (i > -1) { FAV.splice(i, 1); toast(F('{c} favorilerden çıkarıldı.', { c: c })); }
      else if (FAV.length >= FAV_MAX) { toast(F('En fazla {n} favori seçebilirsin. Önce birini çıkar.', { n: FAV_MAX })); return; }
      else { FAV.push(c); toast(F('{c} favorilere eklendi.', { c: c })); }
      saveFav(); refreshFav();
    }
    function refreshFav() {
      majors(); table(); chips();
      var need = FAV.filter(function (c) { return FRANK.indexOf(c) > -1 && !hist[c]; });
      if (need.length) fxHistory(FAV).then(function (h) { hist = h; majors(); chips(); draw(); }).catch(function () {});
    }
    function majors() {
      var el = $('#fx-majors'); if (!el) return;
      setText('#fav-count', FAV.length + '/' + FAV_MAX);
      var html = FAV.filter(function (c) { return R[c]; }).map(function (c) {
        var x = R[c], fs = fser[c + '|30'], sv = hist[c] ? hist[c].filter(Boolean).slice(-30) : fs ? fs.map(function (p) { return p[1]; }) : null;
        if (!sv && FRANK.indexOf(c) < 0) needF(c, 30, majors);
        return '<div class="b major" data-c="' + c + '" role="button" tabindex="0" aria-label="' + F('{c} çeviriciye al', { c: c }) + '">' +
          '<span class="mj-top"><img src="' + flag(c) + '" alt="" width="22" height="22"><b>' + c + '</b><span class="muted">' + (CNAME[c] || '') + '</span></span>' +
          '<span class="mj-val num">' + nf(x.s, dec(x.s)) + ' ₺</span><span class="mj-sub">' + chg(x.c) + ' <span class="muted">· ' + L('alış') + ' ' + nf(x.b, dec(x.b)) + '</span></span>' +
          (sv && sv.length > 2 ? '<svg class="mj-spark" viewBox="0 0 120 32" preserveAspectRatio="none" aria-hidden="true"><path d="' + sparkPath(sv, 120, 32, 3) + '"/></svg>' : '<span class="mj-nochart">' + (fbusy[c + '|30'] ? L('Grafik yükleniyor…') : '&nbsp;') + '</span>') +
          (editing ? '<button type="button" class="mj-del" data-del="' + c + '" aria-label="' + F('{c} favorilerden çıkar', { c: c }) + '"><svg class="icon"><use href="#i-x"/></svg></button>' : '') + '</div>';
      }).join('');
      for (var k = FAV.length; k < FAV_MAX; k++) {
        html += '<label class="b major mj-empty"><svg class="icon"><use href="#i-plus"/></svg><span>' + L('Para birimi ekle') + '</span><select class="mj-pick" aria-label="' + L('Favorilere para birimi ekle') + '"><option value="">' + L('Seç…') + '</option>' +
          codesAll().filter(function (c) { return FAV.indexOf(c) < 0; }).map(function (c) { return '<option value="' + c + '">' + c + ' · ' + (CNAME[c] || '') + '</option>'; }).join('') + '</select></label>';
      }
      el.innerHTML = html;
      el.classList.toggle('editing', editing);
      $$('.major[data-c]', el).forEach(function (b) {
        b.addEventListener('click', function (e) { if (e.target.closest('.mj-del')) return; if (!editing) setFrom(b.dataset.c); });
        b.addEventListener('keydown', function (e) { if (e.key === 'Enter' && !editing) setFrom(b.dataset.c); });
      });
      $$('.mj-del', el).forEach(function (b) { b.addEventListener('click', function () { toggleFav(b.dataset.del); }); });
      $$('.mj-pick', el).forEach(function (s) { s.addEventListener('change', function () { if (s.value) toggleFav(s.value); }); });
    }
    var favEdit = $('#fav-edit');
    if (favEdit) favEdit.addEventListener('click', function () {
      editing = !editing; favEdit.setAttribute('aria-pressed', String(editing));
      favEdit.lastChild.textContent = editing ? L('Bitti') : L('Düzenle');
      $('#fav-hint').hidden = !editing; majors();
    });

    /* ---- tablo ---- */
    function table() {
      var q = search.value.trim().toLocaleLowerCase('tr');
      var codes = codesAll();
      codes = FAV.filter(function (c) { return R[c]; }).concat(codes.filter(function (c) { return FAV.indexOf(c) < 0; }));
      if (sort) {
        var val = function (c) { var x = R[c]; return sort === 'code' ? c : sort === 's' ? x.s : sort === 'spr' ? (x.s - x.b) / x.s : x.c; };
        codes.sort(function (a, b) { var A = val(a), B = val(b); return (A > B ? 1 : A < B ? -1 : 0) * dir; });
      }
      var shown = codes.filter(function (c) { return !q || (c + ' ' + (CNAME[c] || '')).toLocaleLowerCase('tr').indexOf(q) > -1; });
      var total = shown.length, lim = Math.max(10, FAV.filter(function (c) { return R[c]; }).length);
      var cut = !q && !showAll && total > lim + 2;
      if (cut) shown = shown.slice(0, lim);
      var rows = shown.map(function (c) {
        var x = R[c], d = dec(x.s), spr = x.s ? (x.s - x.b) / x.s * 100 : 0, on = FAV.indexOf(c) > -1;
        return '<tr data-c="' + c + '" tabindex="0"' + (c === from.value ? ' class="is-sel"' : '') + '><td><span class="cur"><button type="button" class="star" data-star="' + c + '" aria-pressed="' + on + '" aria-label="' + F(on ? '{c} favorilerden çıkar' : '{c} favorilere ekle', { c: c }) + '"><svg class="icon"><use href="#i-star"/></svg></button><img src="' + flag(c) + '" alt="" width="22" height="22" loading="lazy"><span><b>' + c + '</b><span class="sub">' + (CNAME[c] || '') + '</span></span></span></td>' +
          '<td data-l="Alış">' + nf(x.b, d) + ' ₺</td><td data-l="Satış"><b>' + nf(x.s, d) + ' ₺</b></td><td data-l="Makas">' + pc(nf(spr, 2)) + '</td><td data-l="Günlük">' + chg(x.c) + '</td></tr>';
      }).join('');
      if (!q && total > lim + 2) rows += '<tr class="more-row"><td colspan="5"><button type="button" class="more-btn">' + (cut ? F('Tüm para birimlerini göster ({n})', { n: total }) : L('Daha az göster')) + '</button></td></tr>';
      body.innerHTML = rows || '<tr><td colspan="5" class="muted" style="text-align:center">' + L('Aramana uyan para birimi yok.') + '</td></tr>';
    }
    var showAll = false;
    body.addEventListener('click', function (e) {
      if (e.target.closest('.more-btn')) { var was = showAll; showAll = !showAll; table(); if (was) $('.list-head').scrollIntoView({ block: 'start' }); return; }
      var st = e.target.closest('.star'); if (st) { toggleFav(st.dataset.star); return; }
      var tr = e.target.closest('tr[data-c]'); if (tr) setFrom(tr.dataset.c);
    });
    body.addEventListener('keydown', function (e) { var tr = e.target.closest('tr[data-c]'); if (tr && e.key === 'Enter' && !e.target.closest('.star')) setFrom(tr.dataset.c); });
    search.addEventListener('input', table);
    $$('.th-sort').forEach(function (b) {
      b.addEventListener('click', function () {
        var k = b.dataset.sort;
        if (sort === k) { if (dir === -1) { sort = null; dir = 1; } else dir = -1; } else { sort = k; dir = k === 'code' ? 1 : -1; }
        $$('.th-sort').forEach(function (x) { x.parentNode.setAttribute('aria-sort', x.dataset.sort === sort ? (dir === 1 ? 'ascending' : 'descending') : 'none'); });
        table();
      });
    });
    var sm = $('#fx-sort');
    if (sm) sm.addEventListener('change', function () { var v = sm.value.split(':'); sort = v[0] || null; dir = +v[1] || 1; table(); });

    /* Kaynak bazı kurları 100 kat kaydırılmış verebiliyor (ör. JPY); merkez bankası kuruyla karşılaştırıp düzelt */
    var CHK = null, fixed = {};
    function scaleFix() {
      if (!CHK) return;
      Object.keys(CHK).forEach(function (c) {
        var x = R[c], ref = 1 / CHK[c]; if (!x || fixed[c] === x) return;
        var k = ref / x.s, f = k > 30 && k < 300 ? 100 : k < 1 / 30 && k > 1 / 300 ? 0.01 : 1;
        if (f !== 1) { x.b *= f; x.s *= f; }
        fixed[c] = x;
      });
    }
    getJSON('https://api.frankfurter.dev/v1/latest?base=TRY', 21600).then(function (j) { CHK = j.rates || {}; scaleFix(); convert(); majors(); table(); }).catch(function () {});
    function loadFin() {
      getJSON(API.fin, 110).then(function (j) {
        Object.keys(j).forEach(function (k) { var x = j[k]; if (x && x.Type === 'Currency' && x.Selling > 0) R[k] = { b: x.Buying, s: x.Selling, c: x.Change }; });
        scaleFix();
        if (!from.options.length) options();
        convert(); majors(); table();
        setText('#fx-updated', stamp(j.Update_Date, j.__stale));
      }).catch(function () { fail(body, loadFin); setText('#fx-updated', L('Veri alınamadı')); });
    }
    amt.addEventListener('input', convert);
    amt.addEventListener('focus', function () { amt.select(); });
    from.addEventListener('change', convert); to.addEventListener('change', convert);
    $('#fx-swap').addEventListener('click', function () { var t = from.value; from.value = to.value; to.value = t; convert(); });
    $$('.quick button').forEach(function (b) { b.textContent = nf(+b.dataset.v, 0); });
    $$('.quick button').forEach(function (b) { b.addEventListener('click', function () { amt.value = nf(+b.dataset.v, 0); convert(); }); });
    $$('#conv .seg-btn').forEach(function (b) {
      b.addEventListener('click', function () {
        mode = b.dataset.mode;
        $$('#conv .seg-btn').forEach(function (x) { x.setAttribute('aria-checked', String(x === b)); });
        setText('#cv-note', L(mode === 'sell' ? 'Satış fiyatıyla: banka ya da büro sana döviz satarken bu fiyatı uygular.' : mode === 'buy' ? 'Alış fiyatıyla: elindeki dövizi bozdurduğunda eline yaklaşık bu kadar geçer.' : 'Ortalama: alış ve satış fiyatının ortası. Bankada eline geçecek tutar makas ve vergi nedeniyle farklı olur.'));
        convert();
      });
    });

    /* ---- grafik: üzerinde gezinince değer başlığa yazılır ---- */
    var box = $('#ch-box'), svg = $('#fx-chart'), cur = null, baseStats = '';
    function chips() {
      var list = FAV.length ? FAV.slice() : ['USD'];
      if (list.indexOf(chCur) < 0) chCur = list[0];
      setHTML('#ch-cur', list.map(function (c) { return '<button type="button" class="seg-btn" data-c="' + c + '" aria-pressed="' + (c === chCur) + '">' + c + '</button>'; }).join(''));
      $$('#ch-cur .seg-btn').forEach(function (b) { b.addEventListener('click', function () { chCur = b.dataset.c; chips(); if (FRANK.indexOf(chCur) > -1 && !hist[chCur]) fxHistory(FAV.concat(chCur)).then(function (h) { hist = h; draw(); }); else draw(); }); });
    }
    function draw() {
      var vals = hist[chCur], days = hist.days, pts = [];
      setText('#ch-name', short(chCur));
      if (vals) {
        var cutoff = new Date(); cutoff.setDate(cutoff.getDate() - chDays);
        days.forEach(function (d, i) { if (vals[i] && new Date(d) >= cutoff) pts.push([d, vals[i]]); });
      } else if (FRANK.indexOf(chCur) < 0) {
        var fs = fser[chCur + '|' + chDays];
        if (!fs) { svg.innerHTML = ''; cur = null; setText('#ch-stats', L('Grafik verisi yükleniyor…')); needF(chCur, chDays, draw); return; }
        pts = fs;
      }
      if (pts.length < 2) { svg.innerHTML = ''; cur = null; setText('#ch-stats', L('Bu para birimi için yeterli geçmiş veri yok.')); return; }
      var W = box.clientWidth || 800, H = 240, P = 10, v = pts.map(function (p) { return p[1]; });
      var mn = Math.min.apply(null, v), mx = Math.max.apply(null, v), sp = (mx - mn) || 1;
      var X = function (i) { return i / (pts.length - 1) * W; }, Y = function (y) { return H - 24 - (y - mn) / sp * (H - 24 - P * 2) - P; };
      var line = pts.map(function (p, i) { return (i ? 'L' : 'M') + X(i).toFixed(1) + ' ' + Y(p[1]).toFixed(1); }).join('');
      var up = v[v.length - 1] >= v[0], dd = dec(mx);
      svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
      var lab = function (d) { var x = new Date(d); return x.getDate() + ' ' + TRMON[x.getMonth()] + (chDays > 200 ? ' ' + String(x.getFullYear()).slice(2) : ''); };
      svg.innerHTML = '<line x1="0" x2="' + W + '" y1="' + Y(mx) + '" y2="' + Y(mx) + '" stroke-dasharray="3 4"/><line x1="0" x2="' + W + '" y1="' + Y(mn) + '" y2="' + Y(mn) + '" stroke-dasharray="3 4"/>' +
        '<path class="area' + (up ? '' : ' dn') + '" d="' + line + 'L' + W + ' ' + (H - 24) + 'L0 ' + (H - 24) + 'Z"/><path class="line' + (up ? '' : ' dn') + '" d="' + line + '"/>' +
        '<text x="4" y="' + (Y(mx) + 15) + '">' + nf(mx, dd) + '</text><text x="4" y="' + (Y(mn) - 6) + '">' + nf(mn, dd) + '</text>' +
        '<text x="0" y="' + (H - 4) + '">' + lab(pts[0][0]) + '</text><text x="' + W + '" y="' + (H - 4) + '" text-anchor="end">' + lab(pts[pts.length - 1][0]) + '</text>' +
        '<g id="ch-hl" style="display:none"><line id="ch-vl" y1="0" y2="' + (H - 24) + '"/><circle id="ch-dot" r="5"/></g>';
      var ch = (v[v.length - 1] / v[0] - 1) * 100;
      baseStats = L('Son: ') + '<b>' + nf(v[v.length - 1], dec(v[v.length - 1])) + ' ₺</b> · <span class="' + (up ? 'up' : 'down') + '">' + (up ? '▲' : '▼') + ' ' + pc(nf(Math.abs(ch), 2)) + '</span> · ' + L('en düşük') + ' ' + nf(mn, dd) + ' · ' + L('en yüksek') + ' ' + nf(mx, dd);
      setHTML('#ch-stats', baseStats);
      cur = { pts: pts, X: X, Y: Y, W: W };
    }
    function hover(e) {
      if (!cur) return;
      var r = box.getBoundingClientRect(), fx = Math.max(0, Math.min(1, (e.clientX - r.left) / r.width)), i = Math.round(fx * (cur.pts.length - 1)), p = cur.pts[i];
      var hl = $('#ch-hl'); if (!hl) return; hl.style.display = '';
      var x = cur.X(i), y = cur.Y(p[1]);
      $('#ch-vl').setAttribute('x1', x); $('#ch-vl').setAttribute('x2', x); $('#ch-dot').setAttribute('cx', x); $('#ch-dot').setAttribute('cy', y);
      var d = new Date(p[0]), c0 = (p[1] / cur.pts[0][1] - 1) * 100, up = c0 >= 0;
      setHTML('#ch-stats', '<b>' + trDate(d) + '</b> · <b>' + nf(p[1], dec(p[1])) + ' ₺</b> · <span class="' + (up ? 'up' : 'down') + '">' + (up ? '▲' : '▼') + ' ' + pc(nf(Math.abs(c0), 2)) + '</span> <span class="muted">dönem başına göre</span>');
    }
    function leave() { var hl = $('#ch-hl'); if (hl) hl.style.display = 'none'; setHTML('#ch-stats', baseStats); }
    box.addEventListener('pointermove', hover); box.addEventListener('pointerdown', hover);
    box.addEventListener('pointerleave', leave); box.addEventListener('pointerup', function (e) { if (e.pointerType !== 'mouse') leave(); });
    $$('#ch-range .seg-btn').forEach(function (b) {
      b.addEventListener('click', function () { $$('#ch-range .seg-btn').forEach(function (x) { x.setAttribute('aria-pressed', String(x === b)); }); chDays = +b.dataset.d; draw(); });
    });
    var rt; window.addEventListener('resize', function () { clearTimeout(rt); rt = setTimeout(draw, 150); });
    chips();
    fxHistory(FAV.concat(chCur)).then(function (h) { hist = h; draw(); majors(); }).catch(function () { setText('#ch-stats', L('Grafik verisi alınamadı.')); });
    loadFin(); setInterval(loadFin, 120000);
  }

  /* ---------- Altın ---------- */
  var AU = {
    GRA: ['Gram altın', '24 ayar · 1 gram', 'gram', 'gram'], HAS: ['Has altın', '24 ayar, işçiliksiz · 1 gram', 'gram', 'gram'],
    '18AYARALTIN': ['18 ayar altın', '1 gram', 'gram', 'gram'], '14AYARALTIN': ['14 ayar altın', '1 gram', 'gram', 'gram'],
    CEYREKALTIN: ['Çeyrek altın', '22 ayar · 1,75 g', 'adet', 'coin'], YARIMALTIN: ['Yarım altın', '22 ayar · 3,5 g', 'adet', 'coin'],
    TAMALTIN: ['Tam altın', '22 ayar · 7 g', 'adet', 'coin'], CUMHURIYETALTINI: ['Cumhuriyet altını', '22 ayar · 7,2 g', 'adet', 'coin'],
    ATAALTIN: ['Ata altın', '22 ayar · 7,2 g', 'adet', 'coin'], RESATALTIN: ['Reşat altın', '22 ayar · 7,2 g', 'adet', 'coin'],
    HAMITALTIN: ['Hamit altın', '22 ayar · 7,2 g', 'adet', 'coin'], GREMSEALTIN: ['Gremse altın', '22 ayar · 17,5 g', 'adet', 'coin'],
    IKIBUCUKALTIN: ['İkibuçuk altın', '22 ayar · 18 g', 'adet', 'coin'], BESLIALTIN: ['Beşli altın', '22 ayar · 36 g', 'adet', 'coin'],
    GUMUS: ['Gümüş', '1 gram', 'gram', 'metal'], GPL: ['Platin', '1 gram', 'gram', 'metal'], PAL: ['Paladyum', '1 gram', 'gram', 'metal']
  };
  var AU_ORDER = ['GRA', 'CEYREKALTIN', 'YARIMALTIN', 'TAMALTIN', 'CUMHURIYETALTINI', 'ATAALTIN', 'RESATALTIN', 'HAMITALTIN', 'GREMSEALTIN', 'IKIBUCUKALTIN', 'BESLIALTIN', 'HAS', '18AYARALTIN', '14AYARALTIN', 'GUMUS', 'GPL', 'PAL'];
  function altin() {
    var P = {}, usd = 0, BK = load('rahimov.basket');
    if (!BK || !BK.length) BK = [{ k: 'GRA', q: 1 }];
    function keep() { save('rahimov.basket', BK); }
    function opts(sel) { return AU_ORDER.filter(function (k) { return P[k] || !Object.keys(P).length; }).map(function (k) { return '<option value="' + k + '"' + (k === sel ? ' selected' : '') + '>' + L(AU[k][0]) + '</option>'; }).join(''); }
    function renderBasket() {
      var ul = $('#bk-rows');
      ul.innerHTML = BK.map(function (it, i) {
        var unit = AU[it.k] ? L(AU[it.k][2]) : '';
        return '<li data-i="' + i + '"><select class="select bk-k" aria-label="' + L('Altın türü') + '">' + opts(it.k) + '</select>' +
          '<span class="bk-q"><input class="input num" inputmode="decimal" value="' + (LANG === 'en' ? String(it.q) : String(it.q).replace('.', ',')) + '" aria-label="' + L('Miktar') + '"><small>' + unit + '</small></span>' +
          '<span class="bk-v num">–</span><button type="button" class="icon-btn bk-del" aria-label="' + L('Satırı sil') + '">' + '<svg class="icon"><use href="#i-x"/></svg></button></li>';
      }).join('');
      $$('li', ul).forEach(function (li) {
        var i = +li.dataset.i;
        $('.bk-k', li).addEventListener('change', function (e) { BK[i].k = e.target.value; keep(); renderBasket(); });
        $('input', li).addEventListener('input', function (e) { var v = parseAmt(e.target.value); BK[i].q = isNaN(v) ? 0 : v; keep(); totals(); });
        $('.bk-del', li).addEventListener('click', function () { BK.splice(i, 1); if (!BK.length) BK.push({ k: 'GRA', q: 1 }); keep(); renderBasket(); });
      });
      totals();
    }
    function totals() {
      var tb = 0, ts = 0;
      $$('#bk-rows li').forEach(function (li) {
        var it = BK[+li.dataset.i], p = P[it.k];
        var v = p ? it.q * p.s : NaN; $('.bk-v', li).textContent = isNaN(v) ? '–' : nf(v, 0) + ' ₺';
        if (p) { tb += it.q * p.b; ts += it.q * p.s; }
      });
      setText('#bk-buy', nf(tb, 2) + ' ₺'); setText('#bk-sell', nf(ts, 2) + ' ₺');
      setText('#bk-usd', usd ? F('Dolar karşılığı (bozdurma): yaklaşık {n} $', { n: nf(tb / usd, 0) }) : '');
    }
    $('#bk-add').addEventListener('click', function () { BK.push({ k: 'CEYREKALTIN', q: 1 }); keep(); renderBasket(); var l = $$('#bk-rows input'); if (l.length) l[l.length - 1].focus(); });
    $('#bk-reset').addEventListener('click', function () { BK = [{ k: 'GRA', q: 1 }]; keep(); renderBasket(); });
    function card(k) {
      var p = P[k], a = AU[k], spr = (p.s - p.b) / p.s * 100;
      return '<article class="au-card"><div class="au-name"><h3>' + L(a[0]) + '</h3><small>' + L(a[1]) + '</small></div>' +
        '<div class="au-price num">' + nf(p.s, 2) + ' ₺</div>' +
        '<div class="au-meta num"><span>' + L('alış') + ' ' + nf(p.b, 2) + ' ₺</span><span>' + L('makas') + ' ' + pc(nf(spr, 2)) + '</span></div>' +
        '<div class="au-foot">' + chg(p.c) + '<button type="button" class="linkbtn au-add" data-k="' + k + '" aria-label="' + F('{c} hesaba ekle', { c: L(a[0]) }) + '">' + '<svg class="icon"><use href="#i-plus"/></svg>' + L('Ekle') + '</button></div></article>';
    }
    function grids() {
      var g = { coin: '', gram: '', metal: '' };
      AU_ORDER.forEach(function (k) { if (P[k]) g[AU[k][3]] += card(k); });
      setHTML('#au-coins', g.coin); setHTML('#au-gram', g.gram); setHTML('#au-metal', g.metal);
      $$('.au-add').forEach(function (b) {
        b.addEventListener('click', function () {
          var ex = BK.filter(function (x) { return x.k === b.dataset.k; })[0];
          if (ex) ex.q += 1; else BK.push({ k: b.dataset.k, q: 1 });
          keep(); renderBasket(); b.textContent = L('Eklendi'); setTimeout(function () { b.innerHTML = '<svg class="icon"><use href="#i-plus"/></svg>' + L('Ekle'); }, 1400);
        });
      });
    }
    function hero() {
      var g = P.GRA; if (!g) return;
      setText('#au-gra', nf(g.s, 2) + ' ₺');
      setHTML('#au-gra-sub', chg(g.c) + ' <span class="muted">' + L('bugün') + '</span>');
      setText('#au-buy', nf(g.b, 2) + ' ₺');
      setText('#au-spread', L('makas') + ' ' + pc(nf((g.s - g.b) / g.s * 100, 2)));
      if (usd) { setText('#au-usd', nf(g.s / usd, 2) + ' $'); setText('#au-ons', nf(g.s / usd * 31.1035, 0) + ' $'); }
      if (P.GUMUS) setText('#au-ag', nf(P.GUMUS.s, 2) + ' ₺');
    }
    function go() {
      getJSON(API.fin, 110).then(function (j) {
        var first = !Object.keys(P).length;
        AU_ORDER.forEach(function (k) { var x = j[k]; if (x && x.Selling > 0) P[k] = { b: x.Buying, s: x.Selling, c: x.Change }; });
        usd = j.USD && j.USD.Selling || 0;
        hero(); grids(); if (first) renderBasket(); else totals();
        setText('#gold-updated', stamp(j.Update_Date, j.__stale));
      }).catch(function () { fail($('#au-coins'), go); setText('#gold-updated', L('Veri alınamadı')); });
    }
    renderBasket();
    go(); setInterval(go, 120000);
  }

  /* ---------- Hava durumu ---------- */
  function hava() {
    var box = $('#wx-box');
    var wxTimer;
    initCity(function draw(c) {
      clearInterval(wxTimer); wxTimer = setInterval(function () { draw(getCity()); }, 900000);   /* 15 dk'da bir tazele */
      setText('#wx-city', c.name);
      getJSON(API.wx(c), 900).then(function (j) {
        var cur = j.current, w = wx(cur.weather_code, cur.is_day), D = j.daily;
        var sr = D.sunrise[0].slice(11, 16), ss = D.sunset[0].slice(11, 16);
        var windy = cur.wind_speed_10m >= 30 || (cur.wind_gusts_10m || 0) >= 50;
        var pop0 = D.precipitation_probability_max[0], uv = D.uv_index_max ? D.uv_index_max[0] : null;
        var hero = $('#wx-hero'); if (hero) hero.setAttribute('data-sky', sky(cur.weather_code, cur.is_day));
        function cell(icon, label, val, cls) { return '<div' + (cls ? ' class="' + cls + '"' : '') + '>' + icon + '<dt>' + label + '</dt><dd>' + val + '</dd></div>'; }
        $('#wx-now').innerHTML = '<div class="wx-main">' + wxIcon(w[1]) +
          '<div><div class="wx-temp num">' + Math.round(cur.temperature_2m) + '°</div><div class="wx-desc">' + w[0] + ' · ' + L('hissedilen') + ' ' + Math.round(cur.apparent_temperature) + '°</div>' +
          (windy ? '<span class="wx-badge">' + mi('wind') + L('Rüzgârlı') + '</span>' : '') + '</div></div>' +
          '<dl class="wx-meta">' +
          cell(mi('hum'), L('Nem'), pc(cur.relative_humidity_2m)) +
          cell(mi('wind'), L('Rüzgâr'), Math.round(cur.wind_speed_10m) + ' ' + L('km/sa') + ' ' + mi('arrow', 'transform:rotate(' + Math.round(cur.wind_direction_10m || 0) + 'deg)'), windy ? 'hot' : '') +
          cell(mi('rain'), L('Yağış ihtimali'), pop0 == null ? '—' : pc(pop0), pop0 >= 50 ? 'hot' : '') +
          cell(mi('rise'), L('Gün doğumu'), sr) +
          cell(mi('set'), L('Gün batımı'), ss) +
          (uv != null ? cell(mi('uv'), L('UV indeksi'), Math.round(uv), uv >= 6 ? 'hot' : '') : cell(mi('temp'), L('En düşük / yüksek'), Math.round(D.temperature_2m_min[0]) + '° / ' + Math.round(D.temperature_2m_max[0]) + '°')) +
          '</dl>';
        var start = j.hourly.time.indexOf(cur.time.slice(0, 13) + ':00'); if (start < 0) start = 0;
        var hrs = '', H = j.hourly;
        for (var i = start; i < start + 24 && i < H.time.length; i++) {
          var isDay = H.is_day ? H.is_day[i] : 1, hw = wx(H.weather_code[i], isDay), pp = H.precipitation_probability[i], ws = H.wind_speed_10m ? H.wind_speed_10m[i] : 0;
          hrs += '<div class="hour" data-sky="' + sky(H.weather_code[i], isDay) + '"><span class="h-t">' + (i === start ? L('Şimdi') : H.time[i].slice(11, 16)) + '</span>' + wxIcon(hw[1]) + '<b class="num">' + Math.round(H.temperature_2m[i]) + '°</b>' +
            '<span class="h-p' + (pp >= 30 ? ' on' : '') + '">' + mi('drop') + (pp == null ? '—' : pc(pp)) + '</span>' +
            (ws >= 25 ? '<span class="h-w">' + mi('wind') + Math.round(ws) + '</span>' : '') + '</div>';
        }
        $('#wx-hours').innerHTML = hrs;
        var lo = Math.min.apply(null, D.temperature_2m_min), hi = Math.max.apply(null, D.temperature_2m_max), span = Math.max(1, hi - lo);
        $('#wx-days').innerHTML = D.time.map(function (t, k) {
          var d = new Date(t + 'T12:00:00'), dw = wx(D.weather_code[k], 1), mn = D.temperature_2m_min[k], mx = D.temperature_2m_max[k], pp = D.precipitation_probability_max[k];
          var wk = D.wind_speed_10m_max && D.wind_speed_10m_max[k] >= 35;
          return '<li><div class="d-n"><b>' + (k === 0 ? L('Bugün') : DAYS[d.getDay()]) + '</b><span class="desc">' + dw[0] + (wk ? ' · ' + L('Rüzgârlı') : '') + '</span></div>' +
            '<div class="d-i">' + wxIcon(dw[1]) + (pp >= 20 ? '<span class="d-p">' + pc(pp) + '</span>' : '') + '</div>' +
            '<div class="d-r"><span class="muted num">' + Math.round(mn) + '°</span><span class="bar"><i style="left:' + ((mn - lo) / span * 100).toFixed(1) + '%;right:' + ((hi - mx) / span * 100).toFixed(1) + '%"></i></span><b class="num">' + Math.round(mx) + '°</b></div></li>';
        }).join('');
        box.hidden = false; $('#wx-err').innerHTML = '';
      }).catch(function () { box.hidden = true; fail($('#wx-err'), function () { location.reload(); }); });
    });
  }

  /* ---------- Deprem ---------- */
  function quakeRows(list) {
    return list.map(function (q) {
      var m = +q.mag, cls = m >= 5 ? 'm5' : m >= 4 ? 'm4' : m >= 3 ? 'm3' : '';
      var co = (q.geojson && q.geojson.coordinates) || [];
      var city = q.location_properties && q.location_properties.epiCenter && q.location_properties.epiCenter.name;
      var map = co.length === 2 ? ' <a class="more" style="font-size:13px" target="_blank" rel="noopener" href="https://www.openstreetmap.org/?mlat=' + co[1] + '&mlon=' + co[0] + '#map=9/' + co[1] + '/' + co[0] + '">' + L('harita') + '</a>' : '';
      return '<tr><td><span class="mag ' + cls + '">' + nf(m, 1) + '</span></td><td class="wrap-cell" style="text-align:left"><b>' + esc(q.title || '') + '</b><span class="sub">' + (city ? esc(city) + ' · ' : '') + F('derinlik {n} km', { n: nf(+q.depth, 1) }) + map + '</span></td><td>' + esc(String(q.date_time || '').slice(11, 16)) + '<span class="sub">' + esc(String(q.date_time || '').slice(0, 10).split('-').reverse().join('.')) + '</span></td></tr>';
    }).join('');
  }
  function deprem() {
    var all = [], min = 0, body = $('#q-body'), search = $('#q-search');
    function norm(s) { return String(s).toLocaleLowerCase('tr'); }
    function render() {
      var q = norm(search.value.trim());
      var list = all.filter(function (e) { return +e.mag >= min && (!q || norm(e.title).indexOf(q) !== -1); });
      body.innerHTML = list.length ? quakeRows(list) : '<tr><td colspan="3" style="text-align:center" class="muted">' + L('Bu filtreye uyan deprem yok.') + '</td></tr>';
    }
    function go() {
      getJSON(API.quake, 110).then(function (j) {
        all = j.result || [];
        var now = Date.now(), day = all.filter(function (e) { return now - new Date(String(e.date_time).replace(' ', 'T') + '+03:00').getTime() < 864e5; });
        var mx = day.reduce(function (a, e) { return +e.mag > +a.mag ? e : a; }, day[0] || all[0]);
        setText('#q-count', String(day.length));
        if (mx) { setText('#q-max', nf(+mx.mag, 1)); setText('#q-max-sub', mx.title); }
        if (all[0]) { setText('#q-last', String(all[0].date_time).slice(11, 16)); setText('#q-last-sub', all[0].title + ' · ' + nf(+all[0].mag, 1)); }
        render();
      }).catch(function () { fail(body, function () { location.reload(); }); });
    }
    $$('.q-min').forEach(function (b) {
      b.addEventListener('click', function () {
        min = +b.dataset.min;
        $$('.q-min').forEach(function (x) { x.setAttribute('aria-pressed', String(x === b)); });
        render();
      });
    });
    search.addEventListener('input', render);
    go(); setInterval(go, 120000);
  }

  /* ---------- Namaz vakitleri ---------- */
  var HIJRI = ['Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir', 'Cemaziyelevvel', 'Cemaziyelahir', 'Recep', 'Şaban', 'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce'].map(function (m) { return L('hicri:' + m) === 'hicri:' + m ? m : L('hicri:' + m); });
  var PR = [['Imsak', 'İmsak'], ['Sunrise', 'Güneş'], ['Dhuhr', 'Öğle'], ['Asr', 'İkindi'], ['Maghrib', 'Akşam'], ['Isha', 'Yatsı']];
  /* Vakte göre küçük gökyüzü sahnesi: güneş/ay/yıldız + cami silueti */
  var PKEY = ['imsak', 'gunes', 'ogle', 'ikindi', 'aksam', 'yatsi'];
  var MOSQUE = '<path class="mq" d="M0 100V92h18V78l1.6-6 1.6 6v14h9v-5a8 8 0 0 1 16 0v5h4v-6a19 19 0 0 1 38 0v6h4v-5a8 8 0 0 1 16 0v5h3V78l1.6-6 1.6 6v14H140v8z"/>';
  function stars(list) { return list.map(function (x) { return '<circle class="star" cx="' + x[0] + '" cy="' + x[1] + '" r="' + (x[2] || .9) + '"/>'; }).join(''); }
  function sunG(cx, cy, r, glow) { return '<circle cx="' + cx + '" cy="' + cy + '" r="' + (r * 2.4) + '" fill="' + glow + '" opacity=".28"/><circle cx="' + cx + '" cy="' + cy + '" r="' + (r * 1.6) + '" fill="' + glow + '" opacity=".35"/><circle cx="' + cx + '" cy="' + cy + '" r="' + r + '" fill="#FFE7A3"/>'; }
  function moonG(cx, cy, r) { return '<path fill="#F4EBC8" d="M' + (cx + r * .3) + ' ' + (cy - r) + 'a' + r + ' ' + r + ' 0 1 0 ' + (r * .7) + ' ' + (r * 1.75) + 'a' + (r * .85) + ' ' + (r * .85) + ' 0 1 1-' + (r * .7) + '-' + (r * 1.75) + 'z"/>'; }
  var PRAY_ART = {
    imsak: stars([[18, 14], [40, 8, 1.2], [70, 20], [96, 10], [120, 18, 1.2], [128, 6], [56, 30, .7]]) + moonG(108, 30, 9),
    gunes: sunG(70, 86, 11, '#FFC27A'),
    ogle: sunG(112, 15, 6, '#FFF2B8'),
    ikindi: sunG(113, 72, 6, '#FFD08A'),
    aksam: sunG(70, 82, 13, '#FF9A5C'),
    yatsi: stars([[14, 12, 1.2], [34, 26], [52, 8], [80, 16, 1.2], [92, 34, .7], [126, 10], [118, 30]]) + moonG(104, 26, 10)
  };
  Object.keys(PRAY_ART).forEach(function (k) { PRAY_ART[k] = '<svg class="pray-art" viewBox="0 0 140 100" preserveAspectRatio="xMidYMax slice" aria-hidden="true">' + PRAY_ART[k] + MOSQUE + '</svg>'; });
  function namaz() {
    var tick, grid = $('#pray-grid');
    initCity(function (c) {
      var now = new Date();
      setText('#pray-city', c.name);
      setText('#pray-date', trDate(now) + ', ' + DAYS[now.getDay()]);
      clearInterval(tick);
      getJSON(API.pray(c, pad(now.getDate()) + '-' + pad(now.getMonth() + 1) + '-' + now.getFullYear()), 3600).then(function (j) {
        var t = j.data.timings, h = j.data.date.hijri;
        setText("#pray-hijri", L("Hicri") + " " + +h.day + " " + (HIJRI[h.month.number - 1] || h.month.en) + " " + h.year);
        /* Yatsıdan sonra geri sayım yarının imsakına devam etsin */
        var tmr = null, nd = new Date(now.getTime() + 864e5);
        getJSON(API.pray(c, pad(nd.getDate()) + '-' + pad(nd.getMonth() + 1) + '-' + nd.getFullYear()), 3600).then(function (j2) { tmr = j2.data.timings.Imsak.slice(0, 5); }).catch(function () {});
        function draw() {
          var n = new Date(), cur = n.getHours() * 60 + n.getMinutes(), next = -1;
          PR.forEach(function (p, i) { var a = t[p[0]].slice(0, 5).split(':'); if (next < 0 && +a[0] * 60 + +a[1] > cur) next = i; });
          var late = next < 0 && tmr;   /* yatsı geçti: sıradaki yarının imsakı */
          grid.innerHTML = PR.map(function (p, i) {
            var k = PKEY[i], isN = i === next || (late && i === 0), past = !isN && (next < 0 || i < next);
            return '<div class="pray" data-p="' + k + '"' + (isN ? ' data-next' : past ? ' data-past' : '') + '>' + PRAY_ART[k] + '<small>' + L(p[1]) + '</small><b>' + (late && i === 0 ? tmr : t[p[0]].slice(0, 5)) + '</b>' + (isN ? '<em>' + (late ? L('Yarın') : L('Sıradaki')) + '</em>' : '') + '</div>';
          }).join('');
          if (next < 0 && !tmr) { setText('#pray-next', L('Bugünün vakitleri tamamlandı. Yarının imsak vakti için aşağıdaki aylık tabloya bak.')); return; }
          var nowS = n.getHours() * 3600 + n.getMinutes() * 60 + n.getSeconds();
          var a = (late ? tmr : t[PR[next][0]].slice(0, 5)).split(':'), left = (+a[0] * 60 + +a[1]) * 60 - nowS + (late ? 86400 : 0);
          if (late) next = 0;
          setText('#pray-next', F('{p} vaktine {h} saat {m} dakika {s} saniye kaldı.', { p: L(PR[next][1]), h: Math.floor(left / 3600), m: Math.floor(left % 3600 / 60), s: left % 60 }));
        }
        draw(); tick = setInterval(draw, 1000);
        $('#pray-err').innerHTML = '';
      }).catch(function () { fail($('#pray-err'), function () { location.reload(); }); });
      /* Aylık tablo: varsayılan yakın günler (3 gün önce – 3 gün sonra), 7 gün ya da tüm ay */
      var y = now.getFullYear(), m = now.getMonth(), dim = new Date(y, m + 1, 0).getDate(), d0 = now.getDate();
      function month(yy, mm) {
        if (mm < 0) { yy--; mm = 11; } if (mm > 11) { yy++; mm = 0; }
        return getJSON(API.prayMonth(c, yy, mm + 1), 3600).then(function (j) {
          return j.data.map(function (d) { var g = d.date.gregorian; return { date: new Date(+g.year, +g.month.number - 1, +g.day), t: d.timings }; });
        }).catch(function () { return []; });
      }
      Promise.all([d0 <= 3 ? month(y, m - 1) : Promise.resolve([]), month(y, m), d0 > dim - 6 ? month(y, m + 1) : Promise.resolve([])]).then(function (r) {
        var cur = r[1], all = r[0].concat(cur, r[2]), today = new Date(y, m, d0);
        if (!cur.length) throw 0;
        function render(mode) {
          var list = mode === 'month' ? cur : all.filter(function (x) {
            var k = Math.round((x.date - today) / 864e5);
            return mode === 'week' ? k >= 0 && k < 7 : k >= -3 && k <= 3;
          });
          $('#pray-month').innerHTML = list.map(function (x) {
            var isT = +x.date === +today;
            return '<tr' + (isT ? ' class="is-next"' : '') + '><td><b>' + x.date.getDate() + '<span class="mo"> ' + (LANG === 'tr' || LANG === 'az' ? MONTHS[x.date.getMonth()] : '') + '</span></b>' + (isT ? '<span class="sub">' + L('bugün') + '</span>' : '') + '</td>' + PR.map(function (p) { return '<td>' + x.t[p[0]].slice(0, 5) + '</td>'; }).join('') + '</tr>';
          }).join('');
          var mt = LANG === 'tr' || LANG === 'az' ? cap(MONTHS[m]) + ' ' + y : cap(now.toLocaleDateString(LOC, { month: 'long', year: 'numeric' }));
          setText('#pray-month-title', (mode === 'month' ? mt : mode === 'week' ? L('Önümüzdeki 7 gün') : L('Yakın günler')) + ' — ' + c.name);
          $$('#pm-range .seg-btn').forEach(function (b) { b.setAttribute('aria-pressed', String(b.dataset.r === mode)); });
        }
        var mode = load('rahimov.pmRange') || 'near';
        $$('#pm-range .seg-btn').forEach(function (b) { b.onclick = function () { mode = b.dataset.r; save('rahimov.pmRange', mode); render(mode); }; });
        render(mode);
      }).catch(function () { $('#pray-month').innerHTML = '<tr><td colspan="7" class="muted" style="text-align:center">' + L('Aylık tablo alınamadı.') + '</td></tr>'; });
    });
  }

  /* ---------- Kripto ---------- */
  var COINS = [['bitcoin', 'Bitcoin', 'BTC'], ['ethereum', 'Ethereum', 'ETH'], ['tether', 'Tether', 'USDT'], ['binancecoin', 'BNB', 'BNB'], ['solana', 'Solana', 'SOL'], ['ripple', 'XRP', 'XRP'], ['dogecoin', 'Dogecoin', 'DOGE'], ['cardano', 'Cardano', 'ADA'], ['tron', 'TRON', 'TRX'], ['avalanche-2', 'Avalanche', 'AVAX']];
  function kripto() {
    var body = $('#c-body');
    function go() {
      getJSON(API.crypto, 110).then(function (j) {
        body.innerHTML = COINS.filter(function (c) { return j[c[0]]; }).map(function (c) {
          var x = j[c[0]], d = x.usd < 1 ? 4 : 2;
          return '<tr><td><b>' + c[1] + '</b><span class="sub">' + c[2] + '</span></td><td>' + nf(x.usd, d) + ' $</td><td>' + nf(x.try, d) + ' ₺</td><td>' + chg(x.usd_24h_change) + '</td></tr>';
        }).join('');
        var n = new Date();
        setText('#c-updated', L('Son güncelleme: ') + pad(n.getHours()) + ':' + pad(n.getMinutes()));
      }).catch(function () { fail(body, function () { location.reload(); }); });
    }
    go(); setInterval(go, 120000);
  }

  /* ---------- Resmî tatiller ---------- */
  function tatil() {
    var y = new Date().getFullYear(), body = $('#h-body');
    Promise.all([getJSON(API.hol(y), 86400), getJSON(API.hol(y + 1), 86400).catch(function () { return []; })]).then(function (r) {
      var today = new Date(); today.setHours(0, 0, 0, 0);
      var list = r[0].concat(r[1]).map(function (h) { var d = new Date(h.date + 'T00:00:00'); return { d: d, name: holName(h), left: Math.round((d - today) / 864e5) }; });
      var next = list.filter(function (h) { return h.left >= 0; })[0];
      if (next) {
        setText('#h-next-name', next.name);
        setText('#h-next-date', trDate(next.d) + ', ' + DAYS[next.d.getDay()]);
        setText('#h-next-left', next.left === 0 ? L('Bugün') : F('{n} gün', { n: next.left }));
      }
      body.innerHTML = list.filter(function (h) { return h.left >= -1 || h.d.getFullYear() === y; }).map(function (h) {
        return '<tr' + (h === next ? ' class="is-next"' : '') + '><td class="wrap-cell"><b>' + esc(h.name) + '</b></td><td>' + trDate(h.d) + '</td><td>' + DAYS[h.d.getDay()] + '</td><td>' + (h.left < 0 ? '<span class="muted">' + L('geçti') + '</span>' : h.left === 0 ? L('bugün') : F('{n} gün', { n: h.left })) + '</td></tr>';
      }).join('');
    }).catch(function () { fail(body, function () { location.reload(); }); });
  }

  /* Uygulamada: sekmenin kök sayfası dışındaysan üstte geri çubuğu */
  function appBack() {
    if (!APP) return;
    var root = window.RAHIMOV_TAB_ROOT || '/';
    var path = location.pathname.replace(/^\/(en|ru|az)(?=\/)/, '') || '/';
    if (path === root) return;
    var bar = document.createElement('div');
    bar.className = 'app-back';
    bar.innerHTML = '<button type="button"><svg viewBox="0 0 24 24" width="20" height="20"><path d="M15 5l-7 7 7 7" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>' + L('Geri') + '</button>';
    bar.firstChild.addEventListener('click', function () {
      if (history.length > 1 && document.referrer && document.referrer.indexOf(location.host) > -1) history.back();
      else location.href = lp(root);
    });
    document.body.insertBefore(bar, document.body.firstChild);
  }
  appBack();

  /* Uygulamada: şehir seçimi uygulamanın kendi penceresiyle yapılır; sayfadaki büyük arama alanı yerine küçük bir düğme */
  if (APP) {
    var pop = $('#citypop');
    if (pop) pop.querySelector('summary').addEventListener('click', function (e) { e.preventDefault(); appMsg({ type: 'pickCity' }); });
    $$('.city-pick').forEach(function (el) {
      var c = getCity();
      var b = document.createElement('button');
      b.type = 'button'; b.className = 'app-city';
      b.innerHTML = '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path d="M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="9.5" r="2.5" fill="currentColor"/></svg><span></span><svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true"><path d="M6 9l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/></svg>';
      b.querySelector('span').textContent = c.name;
      b.addEventListener('click', function () { appMsg({ type: 'pickCity' }); });
      el.parentNode.insertBefore(b, el);
      /* Namaz sayfasında şehrin yanına Kıble düğmesi: uygulamanın pusula ekranını açar */
      if ($('#pray-grid')) {
        var q = document.createElement('button');
        q.type = 'button'; q.className = 'app-city app-qibla';
        q.innerHTML = '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 5l3 8h-6z" fill="currentColor"/><path d="M12 19l-3-6h6z" fill="currentColor" opacity=".35"/></svg><span></span>';
        q.querySelector('span').textContent = L('Kıble');
        q.addEventListener('click', function () { appMsg({ type: 'qibla' }); });
        el.parentNode.insertBefore(q, el);
      }
    });
  }

  var pages = { home: home, doviz: doviz, altin: altin, hava: hava, deprem: deprem, namaz: namaz, kripto: kripto, tatil: tatil };
  ticker();
  var p = document.body.getAttribute('data-page');
  if (pages[p]) pages[p]();
})();
