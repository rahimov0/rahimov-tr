/* rahimov.tr — ortak betik: tema, menü ve canlı veri araçları */
(function () {
  'use strict';
  window.__rtr = 1;
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };

  /* ---------- Tema + menü ---------- */
  var root = document.documentElement;
  var themeBtn = $('#themeBtn');
  if (themeBtn) themeBtn.addEventListener('click', function () {
    var cur = root.getAttribute('data-theme') || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    var next = cur === 'dark' ? 'light' : 'dark';
    root.setAttribute('data-theme', next);
    try { localStorage.setItem('theme', next); } catch (e) {}
  });
  var menuBtn = $('#menuBtn'), navLinks = $('#navLinks');
  if (menuBtn) menuBtn.addEventListener('click', function () {
    var open = navLinks.classList.toggle('open');
    menuBtn.setAttribute('aria-expanded', String(open));
  });

  /* ---------- Yardımcılar ---------- */
  function nf(n, d) {
    if (d === undefined) d = 2;
    return new Intl.NumberFormat('tr-TR', { minimumFractionDigits: d, maximumFractionDigits: d }).format(n);
  }
  function esc(s) { return String(s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
  function load(k) { try { return JSON.parse(localStorage.getItem(k)); } catch (e) { return null; } }
  function save(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) {} }
  function timed(url) {
    return new Promise(function (resolve, reject) {
      var done = false, ctl = window.AbortController ? new AbortController() : null;
      var tm = setTimeout(function () { if (!done) { done = true; if (ctl) ctl.abort(); reject(new Error('Zaman aşımı (15 sn)')); } }, 15000);
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
    return once().catch(function () {
      return new Promise(function (res) { setTimeout(res, 1500); }).then(once);   /* geçici/yarım yanıt için bir kez daha dene */
    }).then(function (d) {
      try { sessionStorage.setItem(key, JSON.stringify({ t: now, d: d })); } catch (e) {}
      return d;
    }, function (e) {
      lastErr = (url.split('/')[2] || '') + ' → ' + (e && e.message ? e.message : e);
      throw e;
    });
  }
  function fail(el, retry) {
    if (!el) return;
    el.innerHTML = '<div class="error-box">Veri şu an alınamadı. Bağlantını kontrol edip biraz sonra tekrar dene.' + (lastErr ? ' <small class="muted" style="display:block;margin-top:6px">Ayrıntı: ' + esc(lastErr) + '</small>' : '') + ' <button class="btn btn-secondary btn-sm" type="button" style="margin-left:8px">Tekrar dene</button></div>';
    var b = $('button', el); if (b && retry) b.addEventListener('click', retry);
  }
  function chg(v) {
    if (typeof v !== 'number' || isNaN(v)) return '<span class="muted">—</span>';
    var cls = v > 0 ? 'up' : v < 0 ? 'down' : 'muted';
    return '<span class="' + cls + '">' + (v > 0 ? '▲ ' : v < 0 ? '▼ ' : '') + '%' + nf(Math.abs(v)) + '</span>';
  }
  function pad(n) { return (n < 10 ? '0' : '') + n; }
  function stamp(src) { var n = new Date(); return 'Kaynak verisi: ' + (src || '—') + ' · Son kontrol: ' + pad(n.getHours()) + ':' + pad(n.getMinutes()); }
  function setText(sel, t) { var e = $(sel); if (e) { e.textContent = t; e.classList.remove('skeleton'); } }
  function setHTML(sel, t) { var e = $(sel); if (e) { e.innerHTML = t; e.classList.remove('skeleton'); } }

  var API = {
    fin: 'https://finans.truncgil.com/v4/today.json',
    fxSeries: function (base, start) { return 'https://api.frankfurter.dev/v1/' + start + '..?base=' + base + '&symbols=TRY'; },
    wx: function (c) { return 'https://api.open-meteo.com/v1/forecast?latitude=' + c.lat + '&longitude=' + c.lon + '&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day&hourly=temperature_2m,weather_code,precipitation_probability&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset&timezone=auto&forecast_days=7'; },
    geo: function (q) { return 'https://geocoding-api.open-meteo.com/v1/search?name=' + encodeURIComponent(q) + '&count=8&language=tr'; },
    quake: 'https://api.orhanaydogdu.com.tr/deprem/kandilli/live?limit=100',
    pray: function (c, d) { return 'https://api.aladhan.com/v1/timings/' + d + '?latitude=' + c.lat + '&longitude=' + c.lon + '&method=13'; },
    prayMonth: function (c, y, m) { return 'https://api.aladhan.com/v1/calendar/' + y + '/' + m + '?latitude=' + c.lat + '&longitude=' + c.lon + '&method=13'; },
    crypto: 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,tether,binancecoin,solana,ripple,dogecoin,cardano,tron,avalanche-2&vs_currencies=usd,try&include_24hr_change=true',
    hol: function (y) { return 'https://date.nager.at/api/v3/PublicHolidays/' + y + '/TR'; }
  };

  /* ---------- Şehir seçimi (hava + namaz ortak) ---------- */
  var DEFAULT_CITY = { name: 'İstanbul', lat: 41.0082, lon: 28.9784 };
  function getCity() { var c = load('rahimov.city'); return c && c.lat ? c : DEFAULT_CITY; }
  function initCity(onChange) {
    var input = $('#cityInput'), box = $('#citySuggest'), geoBtn = $('#geoBtn'), timer;
    function pick(c) { save('rahimov.city', c); if (input) input.value = ''; if (box) box.hidden = true; onChange(c); }
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
            if (!res.length) { box.innerHTML = '<button type="button" disabled>Sonuç bulunamadı</button>'; box.hidden = false; return; }
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
    if (geoBtn) {
      if (!navigator.geolocation) geoBtn.hidden = true;
      geoBtn.addEventListener('click', function () {
        geoBtn.disabled = true;
        navigator.geolocation.getCurrentPosition(function (p) {
          geoBtn.disabled = false;
          pick({ name: 'Konumum', lat: +p.coords.latitude.toFixed(3), lon: +p.coords.longitude.toFixed(3) });
        }, function () { geoBtn.disabled = false; geoBtn.textContent = 'Konum alınamadı'; }, { timeout: 8000 });
      });
    }
    onChange(getCity());
  }

  /* ---------- Hava durumu kodları ---------- */
  var WX_ICON = {
    sun: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>',
    moon: '<svg viewBox="0 0 24 24"><path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/></svg>',
    partly: '<svg viewBox="0 0 24 24"><circle cx="8" cy="8" r="3"/><path d="M8 2v1M2 8h1M3.8 3.8l.7.7M12.2 3.8l-.7.7M9 19h8a4 4 0 0 0 .5-8 5.5 5.5 0 0 0-10.4 1.6A3.3 3.3 0 0 0 9 19z"/></svg>',
    cloud: '<svg viewBox="0 0 24 24"><path d="M7 18h10a4.5 4.5 0 0 0 .6-9A6.5 6.5 0 0 0 5.2 10.8 3.7 3.7 0 0 0 7 18z"/></svg>',
    fog: '<svg viewBox="0 0 24 24"><path d="M7 13h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 6.6 3.4 3.4 0 0 0 7 13zM4 17h16M6 21h12"/></svg>',
    rain: '<svg viewBox="0 0 24 24"><path d="M7 14h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 7.6 3.4 3.4 0 0 0 7 14zM8 18l-1 3M12 18l-1 3M16 18l-1 3"/></svg>',
    snow: '<svg viewBox="0 0 24 24"><path d="M7 14h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 7.6 3.4 3.4 0 0 0 7 14zM8 18v.01M12 20v.01M16 18v.01M10 22v.01M14 22v.01"/></svg>',
    storm: '<svg viewBox="0 0 24 24"><path d="M7 14h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 7.6 3.4 3.4 0 0 0 7 14zM13 15l-3 4h4l-3 4"/></svg>'
  };
  function wx(code, isDay) {
    var d = isDay === undefined || isDay ? 1 : 0;
    if (code === 0) return ['Açık', d ? 'sun' : 'moon'];
    if (code === 1) return ['Az bulutlu', d ? 'partly' : 'moon'];
    if (code === 2) return ['Parçalı bulutlu', d ? 'partly' : 'cloud'];
    if (code === 3) return ['Kapalı', 'cloud'];
    if (code === 45 || code === 48) return ['Sisli', 'fog'];
    if (code >= 51 && code <= 55) return ['Çisenti', 'rain'];
    if (code === 56 || code === 57) return ['Dondurucu çisenti', 'rain'];
    if (code === 61) return ['Hafif yağmur', 'rain'];
    if (code === 63) return ['Yağmur', 'rain'];
    if (code === 65) return ['Kuvvetli yağmur', 'rain'];
    if (code === 66 || code === 67) return ['Dondurucu yağmur', 'rain'];
    if (code === 71) return ['Hafif kar', 'snow'];
    if (code === 73) return ['Kar', 'snow'];
    if (code === 75) return ['Yoğun kar', 'snow'];
    if (code === 77) return ['Kar taneleri', 'snow'];
    if (code >= 80 && code <= 82) return ['Sağanak yağış', 'rain'];
    if (code === 85 || code === 86) return ['Kar sağanağı', 'snow'];
    if (code === 95) return ['Gök gürültülü fırtına', 'storm'];
    if (code === 96 || code === 99) return ['Dolulu fırtına', 'storm'];
    return ['—', 'cloud'];
  }
  function wxIcon(name) { return '<span class="wx-ic" aria-hidden="true">' + WX_ICON[name] + '</span>'; }
  var DAYS = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];
  var MONTHS = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  function trDate(d) { return d.getDate() + ' ' + MONTHS[d.getMonth()] + ' ' + d.getFullYear(); }

  /* ---------- Üst şerit (her sayfada) ---------- */
  function ticker() {
    var el = $('#ticker'); if (!el) return;
    getJSON(API.fin, 240).then(function (j) {
      var items = [['USD', 'Dolar', 4], ['EUR', 'Euro', 4], ['GBP', 'Sterlin', 4], ['GRA', 'Gram altın', 2], ['CEYREKALTIN', 'Çeyrek altın', 2], ['GUMUS', 'Gümüş', 2]];
      el.innerHTML = items.filter(function (i) { return j[i[0]] && typeof j[i[0]].Selling === 'number'; }).map(function (i) {
        var x = j[i[0]];
        return '<a class="tick num" href="' + (i[0].length === 3 && i[0] !== 'GRA' ? '/doviz/' : '/altin/') + '"><span>' + i[1] + '</span><b>' + nf(x.Selling, i[2]) + ' ₺</b>' + chg(x.Change) + '</a>';
      }).join('');
    }).catch(function () { el.parentNode.hidden = true; });
  }

  /* ---------- Ana sayfa ---------- */
  function home() {
    function fin() {
      getJSON(API.fin, 110).then(function (j) {
        [['USD', '#t-usd', 4], ['EUR', '#t-eur', 4], ['GRA', '#t-gold', 2]].forEach(function (i) {
          var x = j[i[0]]; if (!x) return;
          setText(i[1], nf(x.Selling, i[2]) + ' ₺');
          setHTML(i[1] + '-sub', chg(x.Change) + ' · alış ' + nf(x.Buying, i[2]));
        });
      }).catch(function () { ['#t-usd', '#t-eur', '#t-gold'].forEach(function (s) { setText(s, '—'); setText(s + '-sub', 'Veri alınamadı'); }); });
    }
    function weather() {
      var c = getCity();
      getJSON(API.wx(c), 900).then(function (j) {
        var w = wx(j.current.weather_code, j.current.is_day);
        setText('#t-wx', Math.round(j.current.temperature_2m) + '°');
        setText('#t-wx-label', c.name);
        setText('#t-wx-sub', w[0] + ' · ' + Math.round(j.daily.temperature_2m_min[0]) + '° / ' + Math.round(j.daily.temperature_2m_max[0]) + '°');
      }).catch(function () { setText('#t-wx', '—'); setText('#t-wx-sub', 'Veri alınamadı'); });
    }
    function quakes() {
      var el = $('#home-quakes'); if (!el) return;
      getJSON(API.quake, 110).then(function (j) {
        el.innerHTML = quakeRows((j.result || []).slice(0, 5));
      }).catch(function () { fail(el.closest('.table-wrap'), quakes); });
    }
    fin(); weather(); quakes();
    setInterval(function () { fin(); quakes(); }, 120000);
  }

  /* ---------- Döviz ---------- */
  var CUR = [['USD', 'ABD Doları'], ['EUR', 'Euro'], ['GBP', 'İngiliz Sterlini'], ['CHF', 'İsviçre Frangı'], ['CAD', 'Kanada Doları'], ['AUD', 'Avustralya Doları'], ['JPY', 'Japon Yeni'], ['SAR', 'Suudi Riyali'], ['AED', 'BAE Dirhemi'], ['KWD', 'Kuveyt Dinarı'], ['QAR', 'Katar Riyali'], ['RUB', 'Rus Rublesi'], ['AZN', 'Azerbaycan Manatı'], ['CNY', 'Çin Yuanı'], ['SEK', 'İsveç Kronu'], ['NOK', 'Norveç Kronu'], ['DKK', 'Danimarka Kronu'], ['BGN', 'Bulgar Levası'], ['RON', 'Rumen Leyi'], ['PLN', 'Polonya Zlotisi']];
  function doviz() {
    var rates = { TRY: 1 }, body = $('#fx-body');
    var amt = $('#fx-amt'), from = $('#fx-from'), to = $('#fx-to'), out = $('#fx-out');
    function convert() {
      var a = parseFloat(String(amt.value).replace(',', '.'));
      if (!rates[from.value] || !rates[to.value] || isNaN(a)) { out.innerHTML = '<b>—</b><span>Bir tutar gir.</span>'; return; }
      var v = a * rates[from.value] / rates[to.value];
      out.innerHTML = '<b>' + nf(v, v < 10 ? 4 : 2) + ' ' + to.value + '</b><span>' + nf(a, 2) + ' ' + from.value + ' · 1 ' + from.value + ' = ' + nf(rates[from.value] / rates[to.value], 4) + ' ' + to.value + ' (alış–satış ortalaması)</span>';
    }
    function loadRates() {
      getJSON(API.fin, 110).then(function (j) {
        var rows = '';
        CUR.forEach(function (c) {
          var x = j[c[0]]; if (!x || typeof x.Selling !== 'number') return;
          rates[c[0]] = (x.Buying + x.Selling) / 2;
          rows += '<tr><td><b>' + c[0] + '</b><span class="sub">' + c[1] + '</span></td><td>' + nf(x.Buying, 4) + '</td><td>' + nf(x.Selling, 4) + '</td><td>' + chg(x.Change) + '</td></tr>';
        });
        body.innerHTML = rows;
        setText('#fx-updated', stamp(j.Update_Date));
        if (!from.options.length) {
          var opts = [['TRY', 'Türk Lirası']].concat(CUR.filter(function (c) { return rates[c[0]]; })).map(function (c) { return '<option value="' + c[0] + '">' + c[0] + ' — ' + c[1] + '</option>'; }).join('');
          from.innerHTML = opts; to.innerHTML = opts; from.value = 'USD'; to.value = 'TRY';
        }
        convert();
      }).catch(function () { fail(body.closest('.table-wrap'), function () { location.reload(); }); });
    }
    [amt, from, to].forEach(function (e) { e.addEventListener('input', convert); });
    $('#fx-swap').addEventListener('click', function () { var t = from.value; from.value = to.value; to.value = t; convert(); });
    loadRates(); setInterval(loadRates, 120000);

    var chartEl = $('#fx-chart');
    function chart(base) {
      var d = new Date(Date.now() - 60 * 864e5);
      var start = d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
      getJSON(API.fxSeries(base, start), 3600).then(function (j) {
        var pts = Object.keys(j.rates).sort().map(function (k) { return [k, j.rates[k].TRY]; });
        drawChart(chartEl, pts, base + '/TRY');
      }).catch(function () { chartEl.innerHTML = ''; setText('#fx-chart-note', 'Grafik verisi şu an alınamadı.'); });
    }
    $$('.fx-base').forEach(function (b) {
      b.addEventListener('click', function () {
        $$('.fx-base').forEach(function (x) { x.setAttribute('aria-pressed', String(x === b)); });
        chart(b.dataset.base);
      });
    });
    chart('USD');
  }
  function drawChart(svg, pts, label) {
    if (!pts.length) return;
    var W = 600, H = 220, L = 8, R = 8, T = 16, B = 28;
    var vals = pts.map(function (p) { return p[1]; });
    var min = Math.min.apply(null, vals), max = Math.max.apply(null, vals);
    if (max === min) { max += 1; min -= 1; }
    var x = function (i) { return L + i * (W - L - R) / (pts.length - 1 || 1); };
    var y = function (v) { return T + (max - v) * (H - T - B) / (max - min); };
    var line = pts.map(function (p, i) { return (i ? 'L' : 'M') + x(i).toFixed(1) + ' ' + y(p[1]).toFixed(1); }).join(' ');
    var area = line + ' L' + x(pts.length - 1).toFixed(1) + ' ' + (H - B) + ' L' + L + ' ' + (H - B) + ' Z';
    var f = function (s) { var a = s.split('-'); return +a[2] + ' ' + MONTHS[+a[1] - 1].slice(0, 3); };
    svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
    svg.setAttribute('aria-label', label + ' kuru, ' + f(pts[0][0]) + ' – ' + f(pts[pts.length - 1][0]));
    svg.innerHTML = '<line x1="' + L + '" x2="' + (W - R) + '" y1="' + (H - B) + '" y2="' + (H - B) + '"/>' +
      '<path class="area" d="' + area + '"/><path class="line" d="' + line + '"/>' +
      '<text x="' + L + '" y="' + (H - 8) + '">' + f(pts[0][0]) + '</text>' +
      '<text x="' + (W - R) + '" y="' + (H - 8) + '" text-anchor="end">' + f(pts[pts.length - 1][0]) + '</text>' +
      '<text x="' + L + '" y="12">en yüksek ' + nf(max, 4) + ' · en düşük ' + nf(min, 4) + '</text>';
  }

  /* ---------- Altın ---------- */
  var GOLD = [['GRA', 'Gram altın', '₺'], ['HAS', 'Has altın (gram)', '₺'], ['CEYREKALTIN', 'Çeyrek altın', '₺'], ['YARIMALTIN', 'Yarım altın', '₺'], ['TAMALTIN', 'Tam altın', '₺'], ['CUMHURIYETALTINI', 'Cumhuriyet altını', '₺'], ['ATAALTIN', 'Ata altın', '₺'], ['RESATALTIN', 'Reşat altın', '₺'], ['14AYARALTIN', '14 ayar altın (gram)', '₺'], ['18AYARALTIN', '18 ayar altın (gram)', '₺'], ['GUMUS', 'Gümüş (gram)', '₺'], ['ONS', 'Ons altın', '$']];
  function altin() {
    var data = {}, body = $('#gold-body'), type = $('#g-type'), qty = $('#g-qty'), out = $('#g-out');
    function calc() {
      var x = data[type.value], q = parseFloat(String(qty.value).replace(',', '.'));
      if (!x || isNaN(q)) { out.innerHTML = '<b>—</b><span>Bir adet ya da gram gir.</span>'; return; }
      out.innerHTML = '<b>' + nf(q * x.Selling) + ' ₺</b><span>Satış fiyatıyla. Bozdurursan (alış fiyatıyla) yaklaşık ' + nf(q * x.Buying) + ' ₺.</span>';
    }
    function go() {
      getJSON(API.fin, 110).then(function (j) {
        var rows = '';
        GOLD.forEach(function (g) {
          var x = j[g[0]]; if (!x || typeof x.Selling !== 'number') return;
          data[g[0]] = x;
          rows += '<tr><td><b>' + g[1] + '</b></td><td>' + nf(x.Buying) + ' ' + g[2] + '</td><td>' + nf(x.Selling) + ' ' + g[2] + '</td><td>' + chg(x.Change) + '</td></tr>';
        });
        body.innerHTML = rows;
        setText('#gold-updated', stamp(j.Update_Date));
        if (!type.options.length) {
          type.innerHTML = GOLD.filter(function (g) { return data[g[0]] && g[2] === '₺'; }).map(function (g) { return '<option value="' + g[0] + '">' + g[1] + '</option>'; }).join('');
        }
        calc();
      }).catch(function () { fail(body.closest('.table-wrap'), function () { location.reload(); }); });
    }
    [type, qty].forEach(function (e) { e.addEventListener('input', calc); });
    go(); setInterval(go, 120000);
  }

  /* ---------- Hava durumu ---------- */
  function hava() {
    var box = $('#wx-box');
    initCity(function (c) {
      setText('#wx-city', c.name);
      getJSON(API.wx(c), 900).then(function (j) {
        var cur = j.current, w = wx(cur.weather_code, cur.is_day);
        var sr = j.daily.sunrise[0].slice(11, 16), ss = j.daily.sunset[0].slice(11, 16);
        $('#wx-now').innerHTML = wxIcon(w[1]) +
          '<div><div class="wx-temp num">' + Math.round(cur.temperature_2m) + '°</div><div class="tile-sub">' + w[0] + ' · hissedilen ' + Math.round(cur.apparent_temperature) + '°</div></div>' +
          '<dl class="wx-meta"><div><dt>Nem</dt><dd>%' + cur.relative_humidity_2m + '</dd></div><div><dt>Rüzgâr</dt><dd>' + Math.round(cur.wind_speed_10m) + ' km/sa</dd></div><div><dt>Yağış ihtimali</dt><dd>%' + (j.daily.precipitation_probability_max[0] == null ? '—' : j.daily.precipitation_probability_max[0]) + '</dd></div><div><dt>Gün doğumu</dt><dd>' + sr + '</dd></div><div><dt>Gün batımı</dt><dd>' + ss + '</dd></div><div><dt>En düşük / yüksek</dt><dd>' + Math.round(j.daily.temperature_2m_min[0]) + '° / ' + Math.round(j.daily.temperature_2m_max[0]) + '°</dd></div></dl>';
        var start = j.hourly.time.indexOf(cur.time.slice(0, 13) + ':00'); if (start < 0) start = 0;
        var hrs = '';
        for (var i = start; i < start + 24 && i < j.hourly.time.length; i++) {
          var hh = +j.hourly.time[i].slice(11, 13), night = hh < +sr.slice(0, 2) || hh > +ss.slice(0, 2);
          hrs += '<div class="hour"><span class="muted">' + j.hourly.time[i].slice(11, 16) + '</span>' + wxIcon(wx(j.hourly.weather_code[i], !night)[1]) + '<b class="num">' + Math.round(j.hourly.temperature_2m[i]) + '°</b><span class="muted">%' + (j.hourly.precipitation_probability[i] == null ? '—' : j.hourly.precipitation_probability[i]) + '</span></div>';
        }
        $('#wx-hours').innerHTML = hrs;
        $('#wx-days').innerHTML = j.daily.time.map(function (t, k) {
          var d = new Date(t + 'T12:00:00'), dw = wx(j.daily.weather_code[k], 1);
          return '<li><b>' + (k === 0 ? 'Bugün' : DAYS[d.getDay()]) + '</b>' + wxIcon(dw[1]) + '<span class="desc">' + dw[0] + ' · yağış %' + (j.daily.precipitation_probability_max[k] == null ? '—' : j.daily.precipitation_probability_max[k]) + '</span><span class="num"><b>' + Math.round(j.daily.temperature_2m_max[k]) + '°</b> <span class="muted">' + Math.round(j.daily.temperature_2m_min[k]) + '°</span></span></li>';
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
      var map = co.length === 2 ? ' <a class="more" style="font-size:13px" target="_blank" rel="noopener" href="https://www.openstreetmap.org/?mlat=' + co[1] + '&mlon=' + co[0] + '#map=9/' + co[1] + '/' + co[0] + '">harita</a>' : '';
      return '<tr><td><span class="mag ' + cls + '">' + nf(m, 1) + '</span></td><td class="wrap-cell" style="text-align:left"><b>' + esc(q.title || '') + '</b><span class="sub">' + (city ? esc(city) + ' · ' : '') + 'derinlik ' + nf(+q.depth, 1) + ' km' + map + '</span></td><td>' + esc(String(q.date_time || '').slice(11, 16)) + '<span class="sub">' + esc(String(q.date_time || '').slice(0, 10).split('-').reverse().join('.')) + '</span></td></tr>';
    }).join('');
  }
  function deprem() {
    var all = [], min = 0, body = $('#q-body'), search = $('#q-search');
    function norm(s) { return String(s).toLocaleLowerCase('tr'); }
    function render() {
      var q = norm(search.value.trim());
      var list = all.filter(function (e) { return +e.mag >= min && (!q || norm(e.title).indexOf(q) !== -1); });
      body.innerHTML = list.length ? quakeRows(list) : '<tr><td colspan="3" style="text-align:center" class="muted">Bu filtreye uyan deprem yok.</td></tr>';
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
      }).catch(function () { fail(body.closest('.table-wrap'), function () { location.reload(); }); });
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
  var HIJRI = ['Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir', 'Cemaziyelevvel', 'Cemaziyelahir', 'Recep', 'Şaban', 'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce'];
  var PR = [['Imsak', 'İmsak'], ['Sunrise', 'Güneş'], ['Dhuhr', 'Öğle'], ['Asr', 'İkindi'], ['Maghrib', 'Akşam'], ['Isha', 'Yatsı']];
  function namaz() {
    var tick, grid = $('#pray-grid');
    initCity(function (c) {
      var now = new Date();
      setText('#pray-city', c.name);
      setText('#pray-date', trDate(now) + ', ' + DAYS[now.getDay()]);
      clearInterval(tick);
      getJSON(API.pray(c, pad(now.getDate()) + '-' + pad(now.getMonth() + 1) + '-' + now.getFullYear()), 3600).then(function (j) {
        var t = j.data.timings, h = j.data.date.hijri;
        setText("#pray-hijri", "Hicri " + +h.day + " " + (HIJRI[h.month.number - 1] || h.month.en) + " " + h.year);
        function draw() {
          var n = new Date(), cur = n.getHours() * 60 + n.getMinutes(), next = -1;
          PR.forEach(function (p, i) { var a = t[p[0]].slice(0, 5).split(':'); if (next < 0 && +a[0] * 60 + +a[1] > cur) next = i; });
          grid.innerHTML = PR.map(function (p, i) {
            return '<div class="card pray' + (i === next ? ' is-next' : '') + '"><small>' + p[1] + '</small><b>' + t[p[0]].slice(0, 5) + '</b></div>';
          }).join('');
          if (next < 0) { setText('#pray-next', 'Bugünün vakitleri tamamlandı. Yarının imsak vakti için aşağıdaki aylık tabloya bak.'); return; }
          var a = t[PR[next][0]].slice(0, 5).split(':'), left = (+a[0] * 60 + +a[1]) * 60 - (n.getHours() * 3600 + n.getMinutes() * 60 + n.getSeconds());
          setText('#pray-next', PR[next][1] + ' vaktine ' + Math.floor(left / 3600) + ' saat ' + Math.floor(left % 3600 / 60) + ' dakika ' + (left % 60) + ' saniye kaldı.');
        }
        draw(); tick = setInterval(draw, 1000);
        $('#pray-err').innerHTML = '';
      }).catch(function () { fail($('#pray-err'), function () { location.reload(); }); });
      getJSON(API.prayMonth(c, now.getFullYear(), now.getMonth() + 1), 3600).then(function (j) {
        $('#pray-month').innerHTML = j.data.map(function (d) {
          var g = d.date.gregorian, today = +g.day === now.getDate();
          return '<tr' + (today ? ' class="is-next"' : '') + '><td><b>' + +g.day + ' ' + MONTHS[now.getMonth()] + '</b></td>' + PR.map(function (p) { return '<td>' + d.timings[p[0]].slice(0, 5) + '</td>'; }).join('') + '</tr>';
        }).join('');
        setText('#pray-month-title', MONTHS[now.getMonth()] + ' ' + now.getFullYear() + ' — ' + c.name);
      }).catch(function () { $('#pray-month').innerHTML = '<tr><td colspan="7" class="muted" style="text-align:center">Aylık tablo alınamadı.</td></tr>'; });
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
        setText('#c-updated', 'Son güncelleme: ' + pad(n.getHours()) + ':' + pad(n.getMinutes()));
      }).catch(function () { fail(body.closest('.table-wrap'), function () { location.reload(); }); });
    }
    go(); setInterval(go, 120000);
  }

  /* ---------- Resmî tatiller ---------- */
  function tatil() {
    var y = new Date().getFullYear(), body = $('#h-body');
    Promise.all([getJSON(API.hol(y), 86400), getJSON(API.hol(y + 1), 86400).catch(function () { return []; })]).then(function (r) {
      var today = new Date(); today.setHours(0, 0, 0, 0);
      var list = r[0].concat(r[1]).map(function (h) { var d = new Date(h.date + 'T00:00:00'); return { d: d, name: h.localName, left: Math.round((d - today) / 864e5) }; });
      var next = list.filter(function (h) { return h.left >= 0; })[0];
      if (next) {
        setText('#h-next-name', next.name);
        setText('#h-next-date', trDate(next.d) + ', ' + DAYS[next.d.getDay()]);
        setText('#h-next-left', next.left === 0 ? 'Bugün' : next.left + ' gün');
      }
      body.innerHTML = list.filter(function (h) { return h.left >= -1 || h.d.getFullYear() === y; }).map(function (h) {
        return '<tr' + (h === next ? ' class="is-next"' : '') + '><td class="wrap-cell"><b>' + esc(h.name) + '</b></td><td>' + trDate(h.d) + '</td><td>' + DAYS[h.d.getDay()] + '</td><td>' + (h.left < 0 ? '<span class="muted">geçti</span>' : h.left === 0 ? 'bugün' : h.left + ' gün') + '</td></tr>';
      }).join('');
    }).catch(function () { fail(body.closest('.table-wrap'), function () { location.reload(); }); });
  }

  var pages = { home: home, doviz: doviz, altin: altin, hava: hava, deprem: deprem, namaz: namaz, kripto: kripto, tatil: tatil };
  ticker();
  var p = document.body.getAttribute('data-page');
  if (pages[p]) pages[p]();
})();
