#!/usr/bin/env python3
"""rahimov.tr statik site üreticisi.  Kullanım:  python3 _src/build.py  (repo kökünde çalıştır)"""
import os, datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = "https://rahimov.tr"
TODAY = datetime.date.today().isoformat()
SPRITE = open(os.path.join(ROOT, "_src", "sprite.html"), encoding="utf-8").read()

ICONS = """
<symbol id="i-menu" viewBox="0 0 24 24"><path d="M4 7h16M4 12h16M4 17h16"/></symbol>
<symbol id="i-fx" viewBox="0 0 24 24"><path d="M4 8h13l-3-3M20 16H7l3 3"/></symbol>
<symbol id="i-gold" viewBox="0 0 24 24"><path d="M8 10h8l2 5H6zM3 20l1.5-4h6L12 20zM12 20l1.5-4h6L21 20zM9 6l1-2M15 6l-1-2M12 5V3"/></symbol>
<symbol id="i-wx" viewBox="0 0 24 24"><circle cx="8" cy="8" r="3"/><path d="M8 2v1M2 8h1M3.8 3.8l.7.7M9 19h8a4 4 0 0 0 .5-8 5.5 5.5 0 0 0-10.4 1.6A3.3 3.3 0 0 0 9 19z"/></symbol>
<symbol id="i-quake" viewBox="0 0 24 24"><path d="M2 12h4l2-6 4 12 3-9 2 3h5"/></symbol>
<symbol id="i-pray" viewBox="0 0 24 24"><path d="M19 14.5A7.5 7.5 0 1 1 9.5 5 6 6 0 0 0 19 14.5zM17 3l.8 1.7L19.5 5.5l-1.7.8L17 8l-.8-1.7-1.7-.8 1.7-.8z"/></symbol>
<symbol id="i-coin" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M9.5 8h3.2a2 2 0 0 1 0 4H9.5zm0 4h3.7a2 2 0 0 1 0 4H9.5zM9.5 8v8M11 6.5V8M11 16v1.5"/></symbol>
<symbol id="i-cal" viewBox="0 0 24 24"><rect x="3.5" y="5" width="17" height="15" rx="2.5"/><path d="M3.5 10h17M8 3v4M16 3v4"/></symbol>
<symbol id="i-pin" viewBox="0 0 24 24"><path d="M12 21s7-6.2 7-11a7 7 0 0 0-14 0c0 4.800 7 11 7 11z"/><circle cx="12" cy="10" r="2.500"/></symbol>
<symbol id="i-game" viewBox="0 0 24 24"><rect x="2.500" y="7" width="19" height="11" rx="5"/><path d="M7 12.500h4M9 10.500v4M15.500 11.500h.01M17.500 13.500h.01"/></symbol>
"""

TOOLS = [
    ("doviz", "/doviz/", "i-fx", "Döviz kurları", "Dolar, euro, sterlin ve 20 para biriminin alış–satış fiyatı, çevirici ve 60 günlük grafik."),
    ("altin", "/altin/", "i-gold", "Altın fiyatları", "Gram, çeyrek, yarım, tam ve Cumhuriyet altını fiyatları ile altın hesaplayıcı."),
    ("hava", "/hava-durumu/", "i-wx", "Hava durumu", "Şehrini ara; anlık sıcaklık, saatlik tahmin ve 7 günlük hava durumu."),
    ("deprem", "/deprem/", "i-quake", "Son depremler", "Kandilli Rasathanesi verileriyle Türkiye ve çevresindeki son 100 deprem."),
    ("namaz", "/namaz-vakitleri/", "i-pray", "Namaz vakitleri", "Bulunduğun şehir için günlük ve aylık vakitler, sıradaki vakte geri sayım."),
    ("kripto", "/kripto/", "i-coin", "Kripto para fiyatları", "Bitcoin, Ethereum ve diğer büyük kripto paraların dolar ve TL fiyatı."),
    ("tatil", "/resmi-tatiller/", "i-cal", "Resmî tatiller", "Bu yılın ve gelecek yılın resmî tatil günleri, bir sonraki tatile kalan gün."),
]

NAV = [("/araclar/", "Araçlar", "araclar"), ("/doviz/", "Döviz", "doviz"), ("/altin/", "Altın", "altin"),
       ("/hava-durumu/", "Hava durumu", "hava"), ("/deprem/", "Deprem", "deprem"), ("/projeler/", "Projeler", "projeler")]

FAVICON = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='15' fill='%231A1917'/%3E%3Cpath d='M22 46V18h12a8 8 0 0 1 0 16H22m12 0 8 12' stroke='%23fff' stroke-width='5' fill='none' stroke-linecap='round' stroke-linejoin='round'/%3E%3Ccircle cx='47' cy='18' r='4' fill='%23FB923C'/%3E%3C/svg%3E"


def icon(name, cls="icon"):
    return f'<svg class="{cls}" aria-hidden="true"><use href="#{name}"/></svg>'


def layout(path, page, title, desc, body, crumbs=None, noindex=False):
    cur = ' aria-current="page"'
    nav = "".join(f'<a href="{h}"{cur if k == page else ""}>{t}</a>' for h, t, k in NAV)
    crumb_html = ""
    if crumbs:
        parts = ['<a href="/">Ana sayfa</a>'] + [f'<a href="{h}">{t}</a>' if h else f"<span>{t}</span>" for h, t in crumbs]
        crumb_html = '<nav class="crumbs wrap" aria-label="Konum">' + " <span>/</span> ".join(parts) + "</nav>"
    tool_links = "".join(f'<li><a href="{t[1]}">{t[3]}</a></li>' for t in TOOLS)
    robots = '<meta name="robots" content="noindex">' if noindex else ""
    return f"""<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title}</title>
<meta name="description" content="{desc}">
<link rel="canonical" href="{SITE}{path}">
{robots}
<meta name="google-adsense-account" content="ca-pub-6811894230993861">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Rahimov">
<meta property="og:url" content="{SITE}{path}">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{desc}">
<meta name="theme-color" content="#FAFAF7" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#0C0C0B" media="(prefers-color-scheme: dark)">
<link rel="icon" href="/favicon.ico" sizes="48x48">
<link rel="icon" type="image/png" href="/icons/icon-192.png" sizes="192x192">
<link rel="icon" href="{FAVICON}" type="image/svg+xml">
<link rel="apple-touch-icon" href="/icons/apple-touch-icon.png">
<link rel="manifest" href="/manifest.webmanifest">
<meta name="apple-mobile-web-app-title" content="Rahimov">
<meta name="mobile-web-app-capable" content="yes">
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-6811894230993861" crossorigin="anonymous"></script>
<script>(function(){{try{{var t=localStorage.getItem('theme');if(t==='light'||t==='dark')document.documentElement.setAttribute('data-theme',t);}}catch(e){{}}}})();</script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,700;12..96,800&family=Geist:wght@400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/assets/site.css?v={TODAY}">
</head>
<body data-page="{page}">
<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">{SPRITE}{ICONS}</svg>

<header class="nav">
  <div class="wrap">
    <a href="/" class="brand" aria-label="Rahimov ana sayfa"><svg class="logo" width="32" height="32" style="border-radius:8px"><use href="#logo-brand"/></svg>Rahimov</a>
    <nav class="nav-links" id="navLinks" aria-label="Ana menü">{nav}</nav>
    <button class="icon-btn theme-btn" type="button" id="themeBtn" aria-label="Açık/koyu tema"><svg class="icon sun"><use href="#i-sun"/></svg><svg class="icon moon"><use href="#i-moon"/></svg></button>
    <button class="icon-btn menu-btn" type="button" id="menuBtn" aria-label="Menü" aria-expanded="false" aria-controls="navLinks">{icon('i-menu')}</button>
  </div>
</header>
<div class="ticker"><div class="wrap" id="ticker" aria-label="Canlı piyasa özeti"></div></div>

{crumb_html}
<main>
{body}
</main>

<footer>
  <div class="wrap">
    <div class="foot-grid">
      <div>
        <a href="/" class="brand"><svg class="logo" width="28" height="28" style="border-radius:7px"><use href="#logo-brand"/></svg>Rahimov</a>
        <p>Günlük hayatta işe yarayan ücretsiz araçlar ve tarayıcıda oynanan oyunlar.</p>
      </div>
      <div><h3>Araçlar</h3><ul>{tool_links}</ul></div>
      <div><h3>Projeler</h3><ul>
        <li><a href="https://abyss-diver.rahimov.tr/">Abyss Diver</a></li>
        <li><a href="https://lexirace.rahimov.tr/">LexiRace</a></li>
        <li><a href="https://spythere.rahimov.tr/">Spythere</a></li>
        <li><a href="https://www.qrcarconnect.com">QR Car Connect</a></li>
        <li><a href="/projeler/">Tüm projeler</a></li></ul></div>
      <div><h3>Site</h3><ul>
        <li><a href="/hakkinda/">Hakkında</a></li>
        <li><a href="/iletisim/">İletişim</a></li>
        <li><a href="/gizlilik/">Gizlilik Politikası</a></li>
        <li><a href="mailto:destek.rahimov@gmail.com">E-posta</a></li>
        <li><a href="https://github.com/rahimov0" target="_blank" rel="noopener">GitHub</a></li></ul></div>
    </div>
    <p class="foot-bottom">© 2026 Kanan Rahimov · rahimov.tr — Buradaki fiyat, hava, deprem ve vakit bilgileri üçüncü taraf kaynaklardan alınır, bilgilendirme amaçlıdır ve gecikmeli olabilir. Yatırım tavsiyesi değildir.</p>
  </div>
</footer>
<script src="/assets/site.js?v={TODAY}" defer></script>
<script>(function(){{var E=[];window.addEventListener('error',function(e){{E.push((e.message||'hata')+(e.filename?' @'+e.filename.split('/').pop()+':'+e.lineno:''));}});
window.addEventListener('load',function(){{setTimeout(function(){{if(!document.querySelector('.skeleton'))return;var d=document.createElement('div');
d.style.cssText='position:fixed;left:8px;right:8px;bottom:8px;z-index:99;background:#7f1d1d;color:#fff;padding:10px 12px;border-radius:10px;font:12px/1.4 sans-serif';
d.textContent='Veriler yüklenemedi. Betik: '+(window.__rtr?'çalıştı':'ÇALIŞMADI')+(E.length?' · Hata: '+E.slice(0,2).join(' | '):'')+' · '+(navigator.onLine?'çevrimiçi':'çevrimdışı');
document.body.appendChild(d);}},12000);}});}})();</script>
</body>
</html>
"""


def faq(items):
    return '<div class="faq">' + "".join(
        f'<details><summary>{q} {icon("i-plus")}</summary><p>{a}</p></details>' for q, a in items) + "</div>"


def page_head(h1, lead, extra=""):
    return f'<section class="page-head"><div class="wrap"><h1>{h1}</h1><p class="lead">{lead}</p>{extra}</div></section>'


def tool_cards(exclude=None):
    return "".join(
        f'<a class="card tool" href="{t[1]}"><span class="tool-ic">{icon(t[2])}</span><div><h3>{t[3]}</h3><p>{t[4]}</p></div></a>'
        for t in TOOLS if t[0] != exclude)


def other_tools(exclude):
    return f'<section class="section"><div class="wrap"><div class="section-head"><h2>Diğer araçlar</h2></div><div class="grid g3">{tool_cards(exclude)}</div></div></section>'


CITYBAR = """<div class="citybar">
  <div class="field"><label for="cityInput">Şehir ya da ilçe ara</label>
    <input class="input" id="cityInput" type="search" placeholder="Örn. Kadıköy, Ankara, Bakü…" autocomplete="off">
    <div class="suggest" id="citySuggest" hidden></div></div>
  <button class="btn btn-secondary" type="button" id="geoBtn">""" + icon("i-pin") + """Konumumu kullan</button>
</div>
<div class="chips" style="margin-bottom:24px">
  <button class="chip city-chip" type="button" data-lat="41.0082" data-lon="28.9784">İstanbul</button>
  <button class="chip city-chip" type="button" data-lat="39.9334" data-lon="32.8597">Ankara</button>
  <button class="chip city-chip" type="button" data-lat="38.4237" data-lon="27.1428">İzmir</button>
  <button class="chip city-chip" type="button" data-lat="40.1885" data-lon="29.0610">Bursa</button>
  <button class="chip city-chip" type="button" data-lat="36.8969" data-lon="30.7133">Antalya</button>
  <button class="chip city-chip" type="button" data-lat="37.0000" data-lon="35.3213">Adana</button>
</div>"""

SK = '<span class="skeleton">00,0000</span>'

# ------------------------------------------------------------------ Projeler
PROJECTS = [
    ("Abyss Diver", "https://abyss-diver.rahimov.tr/", "Macera oyunu · abyss-diver.rahimov.tr", '<img class="logo pixel" src="/logos/abyss-diver.png" alt="Abyss Diver logosu" width="56" height="56" loading="lazy">',
     "Okyanusun derinliklerine inen bir dalgıcı yönetiyorsun. Her bölüm farklı bir harita ve farklı tehlikelerle geliyor; ilerledikçe oyun zorlaşıyor.", ["50 bölüm", "Artan zorluk", "Mobil uyumlu"], "Oyna", True),
    ("LexiRace", "https://lexirace.rahimov.tr/", "Kelime oyunu · lexirace.rahimov.tr", '<img class="logo" src="/logos/lexirace.png" alt="LexiRace logosu" width="56" height="56" loading="lazy">',
     "A'dan Z'ye İngilizce kelime yarışı. Türkçe tanımı görüyorsun, doğru İngilizce kelimeyi süre bitmeden sesli söylüyorsun. A1'den C2'ye seviyeler, günlük görev, Zorlu Mod ve 1v1 düello var.", ["Sesle cevap", "A1–C2", "1v1 düello"], "Oyna", False),
    ("Spythere", "https://spythere.rahimov.tr/", "Parti oyunu · spythere.rahimov.tr", '<img class="logo" src="/logos/spythere.png" alt="Spythere logosu" width="56" height="56" loading="lazy">',
     "Arkadaş grubuyla, herkes kendi telefonundan oynar. Herkes gizli konumu bilir, yalnızca casus bilmez. Sorular sorulur, şüpheler artar ve oyun herkesin oyuyla biter.", ["Çok oyunculu", "Oda modu", "Telefonla"], "Oyna", False),
    ("QR Car Connect", "https://www.qrcarconnect.com", "Uygulama · qrcarconnect.com", '<img class="logo" src="/logos/qr-car-connect.png" alt="QR Car Connect logosu" width="56" height="56" loading="lazy">',
     "Aracına yapıştırdığın QR etiketi sayesinde, numaranı paylaşmadan sana ulaşılabilir. Hazır etiketlerin yanında kendi etiketini tasarlayabileceğin bir araç da var.", ["Numara gizli", "10×5 cm etiket", "Kendin tasarla"], "Aç", False),
    ("Nebula: Infinite Drift", "https://nebula-infinite-drift.vercel.app/", "Uzay oyunu · nebula-infinite-drift.vercel.app", '<svg class="logo" role="img" aria-label="Nebula Drift logosu"><use href="#logo-nebula"/></svg>',
     "Neon ışıklı bir uzayda gemini yönetip düşmanlardan kaçıyor ve ateş ediyorsun. Kısa oturumlar için yapılmış, hızlı bir arcade oyunu.", ["Arcade", "Neon uzay"], "Oyna", False),
    ("Magma Runner", "https://magma-runner.vercel.app/", "Aksiyon oyunu · magma-runner.vercel.app", '<svg class="logo" role="img" aria-label="Magma Runner logosu"><use href="#logo-magma"/></svg>',
     "Lav dolu bir dünyada durmadan koşuyorsun. Refleks ve zamanlama isteyen, hızlı tempolu bir aksiyon oyunu.", ["Refleks", "Hızlı tempo"], "Oyna", False),
    ("Guess the Number", "https://guess-the-number-henna-three.vercel.app/", "Mini oyun · guess-the-number-henna-three.vercel.app", '<img class="logo" src="/logos/guess-the-number.png" alt="Guess the Number logosu" width="56" height="56" loading="lazy">',
     "Gizli sayıyı en kısa sürede bul. Mantığını ve sezgini kullanarak tahminlerini daraltıyorsun. Kısa molalar için ideal.", ["Mantık", "Hızlı tur"], "Oyna", False),
    ("Flamenear", "https://flamenear-dating-app.vercel.app/", "Uygulama prototipi · flamenear-dating-app.vercel.app", '<svg class="logo" role="img" aria-label="Flamenear logosu"><use href="#logo-flamenear"/></svg>',
     "Kaydırarak beğenme özelliğiyle tasarlanmış bir tanışma uygulaması prototipi. Arayüz ve etkileşim denemesi olarak hazırlandı.", ["Prototip", "Kaydırma"], "Aç", False),
    ("Luna Candles", "https://luna-candles-workshop.vercel.app/", "Web tasarım · luna-candles-workshop.vercel.app", '<svg class="logo" role="img" aria-label="Luna Candles logosu"><use href="#logo-luna"/></svg>',
     "El yapımı mum atölyesi için hazırlanmış sade ve sıcak bir tanıtım sayfası tasarımı.", ["Landing page", "E-ticaret"], "Aç", False),
]


def project_cards(limit=None):
    out = ""
    for name, url, meta, logo, desc, tags, cta, new in PROJECTS[:limit]:
        badge = '<span class="badge">Yeni</span>' if new else ""
        out += f"""<article class="card app"><div class="app-head">{logo}<div><h3><a href="{url}" target="_blank" rel="noopener">{name}</a></h3><p class="app-meta">{meta}</p></div>{badge}</div>
<p class="app-desc">{desc}</p><ul class="tags">{''.join(f'<li>{t}</li>' for t in tags)}</ul>
<div class="app-foot"><span class="open">{cta} {icon('i-arrow')}</span></div></article>"""
    return out


PAGES = {}

# ------------------------------------------------------------------ Ana sayfa
PAGES["/"] = dict(page="home", title="Rahimov — Döviz, altın, hava durumu, deprem ve tarayıcı oyunları",
    desc="Canlı döviz ve altın fiyatları, hava durumu, son depremler, namaz vakitleri gibi ücretsiz günlük araçlar ve tarayıcıda oynanan oyunlar tek adreste.",
    body=f"""
<section class="hero"><div class="wrap">
  <p class="eyebrow"><span class="dot"></span>Ücretsiz · kayıt gerekmez</p>
  <h1>Günün verileri ve küçük, işe yarayan araçlar.</h1>
  <p class="lead">Dolar kaç lira, yarın yağmur var mı, az önceki deprem neredeydi? Sık bakılan bilgiler tek sayfada. Yanında da tarayıcıda oynayabileceğin oyunlar var.</p>
  <div class="hero-actions"><a href="/araclar/" class="btn btn-primary">Tüm araçlar</a><a href="/projeler/" class="btn btn-secondary">{icon('i-game')}Oyunlar ve projeler</a></div>
</div></section>

<section class="section" aria-labelledby="ozet-title"><div class="wrap">
  <div class="section-head"><div><h2 id="ozet-title">Şu an</h2><p>Fiyatlar birkaç dakikada bir yenilenir.</p></div></div>
  <div class="grid g4 keep2">
    <a class="card tile" href="/doviz/"><span class="tile-label">Dolar (USD)</span><span class="tile-value" id="t-usd">{SK}</span><span class="tile-sub num" id="t-usd-sub">&nbsp;</span></a>
    <a class="card tile" href="/doviz/"><span class="tile-label">Euro (EUR)</span><span class="tile-value" id="t-eur">{SK}</span><span class="tile-sub num" id="t-eur-sub">&nbsp;</span></a>
    <a class="card tile" href="/altin/"><span class="tile-label">Gram altın</span><span class="tile-value" id="t-gold">{SK}</span><span class="tile-sub num" id="t-gold-sub">&nbsp;</span></a>
    <a class="card tile" href="/hava-durumu/"><span class="tile-label"><span id="t-wx-label">Hava durumu</span></span><span class="tile-value" id="t-wx"><span class="skeleton">00°</span></span><span class="tile-sub" id="t-wx-sub">&nbsp;</span></a>
  </div>
</div></section>

<section class="section" id="araclar" aria-labelledby="araclar-title"><div class="wrap">
  <div class="section-head"><div><h2 id="araclar-title">Araçlar</h2><p>Hepsi ücretsiz, üyelik istemez ve telefonda rahat kullanılır.</p></div></div>
  <div class="grid g3">{tool_cards()}</div>
</div></section>

<section class="section" aria-labelledby="deprem-title"><div class="wrap">
  <div class="section-head"><div><h2 id="deprem-title">Son depremler</h2><p>Kandilli Rasathanesi'nin yayımladığı son beş kayıt.</p></div><a class="more" href="/deprem/">Tüm liste {icon('i-arrow')}</a></div>
  <div class="table-wrap"><table><thead><tr><th>Büyüklük</th><th style="text-align:left">Yer</th><th>Saat</th></tr></thead><tbody id="home-quakes"><tr><td colspan="3" class="muted" style="text-align:center">Yükleniyor…</td></tr></tbody></table></div>
</div></section>

<section class="section" aria-labelledby="projeler-title"><div class="wrap">
  <div class="section-head"><div><h2 id="projeler-title">Oyunlar ve projeler</h2><p>İndirmeden, tarayıcıda açılan oyunlar ve uygulamalar.</p></div><a class="more" href="/projeler/">Tüm projeler {icon('i-arrow')}</a></div>
  <div class="grid g3">{project_cards(6)}</div>
</div></section>

<section class="section"><div class="wrap">
  <div class="section-head"><h2>Sık sorulan sorular</h2></div>
  {faq([
    ("Bu site ne işe yarıyor?", "Gün içinde sık sık baktığın bilgileri tek yerde topluyor: döviz ve altın fiyatları, hava durumu, son depremler, namaz vakitleri, kripto para fiyatları ve resmî tatiller. Ayrıca Kanan Rahimov'un geliştirdiği tarayıcı oyunlarına ve uygulamalara buradan ulaşabilirsin."),
    ("Veriler nereden geliyor?", "Her aracın sayfasında kaynağı yazıyor. Döviz ve altın için Truncgil Finans ve Frankfurter, hava durumu için Open-Meteo, depremler için Kandilli Rasathanesi verisi, namaz vakitleri için Aladhan, kripto için CoinGecko, tatiller için Nager.Date kullanılıyor."),
    ("Fiyatlar anlık mı?", "Döviz, altın ve kripto fiyatları birkaç dakikada bir güncellenir; saniyelik borsa verisi değildir. Banka ve kuyumcu fiyatları burada gördüğünden farklı olabilir. Buradaki bilgiler yatırım tavsiyesi değildir."),
    ("Üye olmam ya da uygulama indirmem gerekiyor mu?", "Hayır. Araçların hepsi tarayıcıda çalışır ve üyelik istemez. Seçtiğin şehir ve tema tercihi yalnızca kendi cihazında saklanır."),
    ("Sitede neden reklam var?", "Bazı sayfalarda Google reklamları gösterilebilir. Bu gelir, alan adı ve hizmet masraflarını karşılayıp araçların ücretsiz kalmasına yardım ediyor. Ayrıntılar <a href='/gizlilik/'>Gizlilik Politikası</a> sayfasında."),
  ])}
</div></section>
""")

# ------------------------------------------------------------------ Araçlar
PAGES["/araclar/"] = dict(page="araclar", title="Ücretsiz günlük araçlar — Rahimov",
    desc="Döviz çevirici, altın hesaplayıcı, hava durumu, son depremler, namaz vakitleri, kripto fiyatları ve resmî tatiller: ücretsiz ve üyeliksiz araçlar.",
    crumbs=[(None, "Araçlar")],
    body=page_head("Araçlar", "Gün içinde sık bakılan bilgiler için yedi küçük araç. Hepsi ücretsiz, üyelik istemez ve telefonda rahat kullanılır.") + f"""
<section class="section"><div class="wrap"><div class="grid g3">{tool_cards()}</div>
<div class="prose">
  <h2>Bu araçlar nasıl çalışıyor?</h2>
  <p>Sayfayı açtığında tarayıcın, ilgili bilgiyi doğrudan açık veri kaynaklarından alır ve ekranda gösterir. Arada bir üyelik sistemi ya da kişisel veri toplayan bir sunucu yoktur. Seçtiğin şehir ve tema tercihi yalnızca kendi cihazında saklanır; böylece bir sonraki gelişinde hava durumu ve namaz vakitleri doğrudan senin şehrinle açılır.</p>
  <p>Fiyat sayfaları (döviz, altın, kripto) açık kaldığı sürece iki dakikada bir kendini yeniler. Deprem listesi de aynı aralıkla güncellenir. Kaynaklardan biri geçici olarak yanıt vermezse sayfada bunu söyleyen bir uyarı ve “Tekrar dene” düğmesi görürsün.</p>
  <h2>Kaynaklar</h2>
  <ul>
    <li><strong>Döviz ve altın:</strong> Truncgil Finans (serbest piyasa alış–satış fiyatları) ve Frankfurter (merkez bankası referans kurları, grafik için).</li>
    <li><strong>Hava durumu:</strong> Open-Meteo; ulusal meteoroloji kurumlarının sayısal hava tahmin modellerini kullanır.</li>
    <li><strong>Depremler:</strong> Boğaziçi Üniversitesi Kandilli Rasathanesi'nin yayımladığı liste.</li>
    <li><strong>Namaz vakitleri:</strong> Aladhan; Diyanet İşleri Başkanlığı'nın hesaplama yöntemi seçili.</li>
    <li><strong>Kripto paralar:</strong> CoinGecko.</li>
    <li><strong>Resmî tatiller:</strong> Nager.Date.</li>
  </ul>
  <p class="note">Buradaki bilgiler bilgilendirme amaçlıdır. Para ile ilgili kararlarda bankanın ya da kuyumcunun güncel fiyatını, afet durumlarında AFAD ve resmî kurumların duyurularını esas al.</p>
</div></div></section>""")

# ------------------------------------------------------------------ Döviz
PAGES["/doviz/"] = dict(page="doviz", title="Döviz kurları ve döviz çevirici — Dolar, Euro, Sterlin kaç TL?",
    desc="Güncel dolar, euro, sterlin ve 20 para biriminin alış–satış fiyatı. Döviz çevirici ve 60 günlük kur grafiği. Ücretsiz, üyeliksiz.",
    crumbs=[("/araclar/", "Araçlar"), (None, "Döviz kurları")],
    body=page_head("Döviz kurları ve çevirici", "Serbest piyasa alış–satış fiyatları, hızlı bir çevirici ve son 60 günün grafiği.",
        '<p class="updated"><span class="live-dot"></span><span id="fx-updated">Yükleniyor…</span> · 2 dakikada bir yenilenir</p>') + f"""
<section class="section"><div class="wrap">
  <div class="card" style="margin-bottom:24px">
    <h2 style="font-size:22px;line-height:28px;margin-bottom:16px">Döviz çevirici</h2>
    <div class="form-row">
      <div class="field"><label for="fx-amt">Tutar</label><input class="input num" id="fx-amt" type="text" inputmode="decimal" value="100"></div>
      <div class="field"><label for="fx-from">Bu para biriminden</label><select class="select" id="fx-from"></select></div>
      <button class="icon-btn swap" type="button" id="fx-swap" aria-label="Para birimlerini değiştir" style="height:48px;width:48px">{icon('i-fx')}</button>
      <div class="field"><label for="fx-to">Bu para birimine</label><select class="select" id="fx-to"></select></div>
    </div>
    <div class="result" id="fx-out" aria-live="polite"><b>—</b><span>Kurlar yükleniyor…</span></div>
  </div>

  <div class="table-wrap"><table>
    <thead><tr><th>Para birimi</th><th>Alış (₺)</th><th>Satış (₺)</th><th>Günlük değişim</th></tr></thead>
    <tbody id="fx-body"><tr><td colspan="4" class="muted" style="text-align:center">Yükleniyor…</td></tr></tbody>
  </table></div>

  <div class="card" style="margin-top:24px">
    <div class="section-head" style="margin-bottom:12px"><h2 style="font-size:22px;line-height:28px">Son 60 gün</h2>
      <div class="chips"><button class="chip fx-base" type="button" data-base="USD" aria-pressed="true">Dolar</button><button class="chip fx-base" type="button" data-base="EUR" aria-pressed="false">Euro</button><button class="chip fx-base" type="button" data-base="GBP" aria-pressed="false">Sterlin</button></div></div>
    <svg class="chart" id="fx-chart" role="img" preserveAspectRatio="none"></svg>
    <p class="muted" id="fx-chart-note" style="font-size:13px;margin-top:8px">Grafik, merkez bankalarının yayımladığı günlük referans kurlarını gösterir; hafta sonları ve tatillerde veri yoktur.</p>
  </div>

  <div class="prose">
    <h2>Alış ve satış fiyatı ne demek?</h2>
    <p><strong>Alış fiyatı</strong>, banka ya da döviz bürosunun senden dövizi aldığı fiyattır; yani elindeki doları bozdurduğunda eline geçen tutar. <strong>Satış fiyatı</strong> ise sana döviz satarken istedikleri fiyattır. Satış fiyatı her zaman alış fiyatından yüksektir. Aradaki farka <strong>makas</strong> (spread) denir ve kurumun kazancını oluşturur.</p>
    <p>Bu yüzden 100 dolar alıp hemen geri bozdurursan, kur hiç değişmese bile birkaç lira kaybedersin. Makas, piyasanın açık olduğu saatlerde dar, akşam ve hafta sonu ise geniş olur. Bankaların mobil uygulamalarında mesai dışında gördüğün fiyatların daha kötü olmasının nedeni budur.</p>
    <h2>Buradaki kur ile bankamdaki kur neden farklı?</h2>
    <p>Tabloda gördüğün fiyatlar serbest piyasadaki ortalama alış–satış fiyatlarıdır. Her banka ve döviz bürosu bu fiyatın üzerine kendi makasını koyar. Ayrıca Türkiye'de döviz alırken satış tutarı üzerinden <strong>kambiyo vergisi (BSMV)</strong> ödenir; bu vergi de ödediğin toplam tutarı artırır. Sonuçta bankada göreceğin fiyat buradakinden biraz farklı olur. Büyük tutarlı işlemlerde birkaç kurumun fiyatını karşılaştırmak işe yarar.</p>
    <h2>Çevirici nasıl hesaplıyor?</h2>
    <p>Çevirici, her para biriminin alış ve satış fiyatının ortalamasını kullanır. İki yabancı para birimi arasında çeviri yaparken (örneğin euro → dolar) her ikisinin TL karşılığı üzerinden <strong>çapraz kur</strong> hesaplar. Sonuç yaklaşık bir değerdir; gerçek işlemde eline geçecek tutar, işlem yaptığın kurumun fiyatına göre değişir.</p>
    <h2>Merkez Bankası kuru nedir?</h2>
    <p>Türkiye Cumhuriyet Merkez Bankası (TCMB) her iş günü öğleden sonra <strong>gösterge niteliğinde kurlar</strong> yayımlar. Bu kurlar resmî işlemlerde, vergi hesaplarında, fatura ve sözleşmelerde kullanılır. Serbest piyasadaki anlık fiyat gün içinde TCMB kurundan uzaklaşabilir. Sayfadaki grafik, bu tür günlük referans kurlarına dayanır; tablo ise piyasa fiyatını gösterir.</p>
    <h2>Sık sorulan sorular</h2>
  </div>
  {faq([
    ("Kurlar ne sıklıkla güncelleniyor?", "Tablo, sayfa açık kaldığı sürece iki dakikada bir yenilenir. Kaynağın son güncelleme saati sayfanın üstünde yazar. Hafta sonu piyasalar kapalı olduğu için fiyatlar çok az değişir."),
    ("Günlük değişim neye göre hesaplanıyor?", "Yüzde değişim, bir önceki günün kapanış fiyatına göre bugünkü farkı gösterir. Yeşil yukarı ok artışı, kırmızı aşağı ok düşüşü ifade eder."),
    ("Bu fiyatlarla işlem yapabilir miyim?", "Hayır. Bu sayfa yalnızca bilgi verir; alım satım yapılmaz. İşlem yapacağın bankanın ya da döviz bürosunun güncel fiyatını esas al."),
    ("Veri kaynağı nedir?", "Alış–satış fiyatları Truncgil Finans'tan, grafik verisi Frankfurter'in derlediği merkez bankası referans kurlarından alınır."),
  ])}
  <p class="note" style="max-width:760px">Bu sayfadaki bilgiler yatırım tavsiyesi değildir. Fiyatlar gecikmeli olabilir.</p>
</div></section>""" + other_tools("doviz"))

# ------------------------------------------------------------------ Altın
PAGES["/altin/"] = dict(page="altin", title="Altın fiyatları — Gram, çeyrek, yarım, tam altın kaç TL?",
    desc="Güncel gram altın, çeyrek altın, yarım, tam ve Cumhuriyet altını alış–satış fiyatları. Altın hesaplayıcı ile elindeki altının değerini bul.",
    crumbs=[("/araclar/", "Araçlar"), (None, "Altın fiyatları")],
    body=page_head("Altın fiyatları", "Gram, çeyrek, yarım, tam ve Cumhuriyet altınının alış–satış fiyatları ve basit bir hesaplayıcı.",
        '<p class="updated"><span class="live-dot"></span><span id="gold-updated">Yükleniyor…</span> · 2 dakikada bir yenilenir</p>') + f"""
<section class="section"><div class="wrap">
  <div class="card" style="margin-bottom:24px">
    <h2 style="font-size:22px;line-height:28px;margin-bottom:16px">Altın hesaplayıcı</h2>
    <div class="grid g2">
      <div class="field"><label for="g-type">Altın türü</label><select class="select" id="g-type"></select></div>
      <div class="field"><label for="g-qty">Adet ya da gram</label><input class="input num" id="g-qty" type="text" inputmode="decimal" value="1"></div>
    </div>
    <div class="result" id="g-out" aria-live="polite"><b>—</b><span>Fiyatlar yükleniyor…</span></div>
  </div>

  <div class="table-wrap"><table>
    <thead><tr><th>Tür</th><th>Alış</th><th>Satış</th><th>Günlük değişim</th></tr></thead>
    <tbody id="gold-body"><tr><td colspan="4" class="muted" style="text-align:center">Yükleniyor…</td></tr></tbody>
  </table></div>

  <div class="prose">
    <h2>Altın türleri arasındaki fark</h2>
    <p>Türkiye'de altın, birikim aracı olarak en çok gram altın ve ziynet altınları (çeyrek, yarım, tam) şeklinde alınır. Aralarındaki temel fark <strong>ayar</strong> (saflık) ve <strong>ağırlıktır</strong>.</p>
    <ul>
      <li><strong>Gram altın:</strong> 24 ayar, yani neredeyse saf altındır. Külçe ya da küçük paketler hâlinde satılır. İşçilik payı düşük olduğu için alış–satış farkı en dar olan türdür.</li>
      <li><strong>Çeyrek altın:</strong> 22 ayar, yaklaşık 1,75 gramdır. Düğün ve bayram hediyesi olarak en yaygın türdür.</li>
      <li><strong>Yarım altın:</strong> 22 ayar, yaklaşık 3,5 gramdır.</li>
      <li><strong>Tam altın:</strong> 22 ayar, yaklaşık 7 gramdır.</li>
      <li><strong>Cumhuriyet altını ve Ata altın:</strong> Darphane'nin bastığı, 22 ayar ve yaklaşık 7,2 gram ağırlığındaki altınlardır.</li>
      <li><strong>14 ve 18 ayar altın:</strong> Takılarda kullanılır. 14 ayar altının 1000'de 585'i, 18 ayar altının 1000'de 750'si saf altındır.</li>
      <li><strong>Ons altın:</strong> Uluslararası piyasalarda kullanılan ölçüdür; bir ons yaklaşık 31,1 gramdır ve fiyatı dolar olarak verilir.</li>
    </ul>
    <h2>Ayar ne demek?</h2>
    <p>Ayar, bir altın alaşımının 24 parçasından kaçının saf altın olduğunu gösterir. 24 ayar saf altın, 22 ayar ise 24 parçanın 22'si altın (yaklaşık binde 916) demektir. Geri kalan kısım, altını daha dayanıklı yapmak için eklenen bakır ve gümüş gibi metallerdir. Ayar düştükçe altının fiyatı da düşer.</p>
    <h2>Gram altın fiyatı nasıl oluşur?</h2>
    <p>Gram altının TL fiyatı iki şeye bağlıdır: uluslararası piyasadaki <strong>ons altın fiyatı</strong> ve <strong>dolar/TL kuru</strong>. Kabaca, ons fiyatının dolar kuruyla çarpılıp 31,1'e bölünmesiyle bulunur. Bu yüzden ons altın yerinde saysa bile dolar yükselirse gram altın da yükselir. İkisinin aynı anda artması gram altında en hızlı yükselişi getirir.</p>
    <h2>Alırken ve bozdururken nelere dikkat etmeli?</h2>
    <ul>
      <li>Kuyumcuların fiyatı, tabloda gördüğün piyasa fiyatından farklıdır. Ziynet altınlarında işçilik payı fiyata eklenir.</li>
      <li>Alış ve satış arasındaki fark, çeyrek gibi küçük ziynet altınlarında gram altına göre daha yüksektir. Sık al-sat yapacaksan bu farkı hesaba kat.</li>
      <li>Eski tarihli ziynet altınları genelde yeni tarihlilere göre biraz daha düşük fiyattan alınır.</li>
      <li>Bankalardaki altın hesaplarında fiziksel altın teslim almazsın; işlem saatleri ve makas bankadan bankaya değişir.</li>
    </ul>
    <h2>Sık sorulan sorular</h2>
  </div>
  {faq([
    ("Hesaplayıcı hangi fiyatı kullanıyor?", "Ana sonuç satış fiyatıyla hesaplanır; yani o miktarda altını almak için ödeyeceğin yaklaşık tutardır. Altında, elindeki altını bozdurduğunda (alış fiyatıyla) eline geçecek yaklaşık tutar da gösterilir."),
    ("Kuyumcudaki fiyat neden farklı?", "Tablodaki fiyatlar piyasa ortalamasıdır. Kuyumcular kendi kâr payını ve ziynet altınlarında işçilik payını ekler. Şehre ve kuyumcuya göre küçük farklar olması normaldir."),
    ("Gümüş fiyatı da var mı?", "Evet, tabloda gram gümüşün TL fiyatı da yer alır."),
    ("Veri kaynağı nedir?", "Fiyatlar Truncgil Finans'tan alınır ve sayfa açık kaldığı sürece iki dakikada bir yenilenir."),
  ])}
  <p class="note" style="max-width:760px">Bu sayfadaki bilgiler yatırım tavsiyesi değildir. Fiyatlar gecikmeli olabilir.</p>
</div></section>""" + other_tools("altin"))

# ------------------------------------------------------------------ Hava
PAGES["/hava-durumu/"] = dict(page="hava", title="Hava durumu — Anlık, saatlik ve 7 günlük tahmin",
    desc="Şehrini ya da ilçeni ara; anlık sıcaklık, hissedilen sıcaklık, rüzgâr, nem, saatlik tahmin ve 7 günlük hava durumunu gör.",
    crumbs=[("/araclar/", "Araçlar"), (None, "Hava durumu")],
    body=page_head("Hava durumu", "Şehrini ya da ilçeni seç; anlık durumu, önümüzdeki 24 saati ve 7 günü gör.") + f"""
<section class="section"><div class="wrap">
  {CITYBAR}
  <div id="wx-err"></div>
  <div id="wx-box" hidden>
    <div class="card" style="margin-bottom:16px">
      <p class="tile-label" style="margin-bottom:12px"><span id="wx-city">—</span><span>Şu an</span></p>
      <div class="wx-now" id="wx-now"></div>
    </div>
    <h2 style="font-size:22px;line-height:28px;margin:32px 0 12px">Önümüzdeki 24 saat</h2>
    <div class="hours" id="wx-hours"></div>
    <h2 style="font-size:22px;line-height:28px;margin:32px 0 4px">7 günlük tahmin</h2>
    <div class="card"><ul class="days" id="wx-days"></ul></div>
  </div>

  <div class="prose">
    <h2>Tahminler nasıl okunur?</h2>
    <p><strong>Hissedilen sıcaklık</strong>, termometrenin gösterdiği değer değil, vücudunun algıladığı sıcaklıktır. Rüzgâr soğuk havayı daha soğuk, nem ise sıcak havayı daha bunaltıcı hissettirir. Kışın rüzgârlı bir günde 5 derece, 0 derece gibi hissedilebilir.</p>
    <p><strong>Yağış ihtimali</strong>, o saat ya da gün içinde bulunduğun yerde ölçülebilir yağış olma olasılığıdır. Yüzde 30, “günün yüzde 30'unda yağacak” demek değildir; benzer hava koşullarında on günün üçünde yağış görüldüğü anlamına gelir. Yüzde 60 ve üzerindeyse yanına şemsiye almak mantıklıdır.</p>
    <p><strong>Rüzgâr hızı</strong> yerden 10 metre yükseklikteki ortalama hızdır. 20 km/sa altı hafif, 40 km/sa civarı kuvvetli, 60 km/sa ve üzeri fırtına düzeyindedir.</p>
    <h2>Tahminler ne kadar güvenilir?</h2>
    <p>Hava tahminleri, atmosferi sayısal modellerle hesaplayan süper bilgisayarlardan gelir. Önümüzdeki bir–üç gün için tahminler genellikle isabetlidir. Dördüncü günden sonra belirsizlik artar; yedinci güne dair tahmini bir eğilim olarak görmek daha doğrudur. Sağanak ve gök gürültülü fırtına gibi yerel olayların tam yeri ve saati ise bir gün öncesinden bile kesin bilinemez.</p>
    <p>Dağlık bölgelerde ve kıyı şeridinde, birkaç kilometre arayla hava belirgin biçimde değişebilir. Bu yüzden il merkezi yerine doğrudan ilçeni aratman daha doğru sonuç verir.</p>
    <h2>Veri kaynağı</h2>
    <p>Tahminler <a href="https://open-meteo.com/" target="_blank" rel="noopener">Open-Meteo</a> üzerinden alınır. Open-Meteo, ulusal meteoroloji kurumlarının açık hava modellerini birleştirir. Şiddetli hava olaylarında Meteoroloji Genel Müdürlüğü'nün resmî uyarılarını takip et.</p>
    <h2>Sık sorulan sorular</h2>
  </div>
  {faq([
    ("Şehrimi her seferinde yeniden seçmem gerekiyor mu?", "Hayır. Seçtiğin şehir cihazında saklanır; siteye tekrar geldiğinde hava durumu ve namaz vakitleri aynı şehirle açılır."),
    ("“Konumumu kullan” ne yapıyor?", "Tarayıcın izin isteyip konumunu tahmini olarak alır ve tahmini tam bulunduğun nokta için getirir. Konum bilgisi yalnızca hava durumu sorgusu için kullanılır ve bu site tarafından saklanmaz."),
    ("Yurt dışındaki şehirler için de çalışıyor mu?", "Evet. Arama kutusuna dünyadaki herhangi bir şehri yazabilirsin; saatler o şehrin yerel saatine göre gösterilir."),
    ("Tahminler ne sıklıkla güncelleniyor?", "Modeller gün içinde birkaç kez yeniden çalıştırılır. Sayfayı yenilediğinde en güncel tahmini görürsün."),
  ])}
</div></section>""" + other_tools("hava"))

# ------------------------------------------------------------------ Deprem
PAGES["/deprem/"] = dict(page="deprem", title="Son depremler — Kandilli Rasathanesi canlı deprem listesi",
    desc="Türkiye ve çevresindeki son 100 deprem: büyüklük, yer, derinlik ve saat. Büyüklüğe göre filtrele, ilini ara. Kandilli Rasathanesi verisi.",
    crumbs=[("/araclar/", "Araçlar"), (None, "Son depremler")],
    body=page_head("Son depremler", "Kandilli Rasathanesi'nin yayımladığı son 100 kayıt. Liste 2 dakikada bir yenilenir.") + f"""
<section class="section"><div class="wrap">
  <div class="grid g3" style="margin-bottom:24px">
    <div class="card tile"><span class="tile-label">Son 24 saatte</span><span class="tile-value" id="q-count"><span class="skeleton">00</span></span><span class="tile-sub">kayıtlı deprem</span></div>
    <div class="card tile"><span class="tile-label">Son 24 saatin en büyüğü</span><span class="tile-value" id="q-max"><span class="skeleton">0,0</span></span><span class="tile-sub" id="q-max-sub">&nbsp;</span></div>
    <div class="card tile"><span class="tile-label">En son deprem</span><span class="tile-value" id="q-last"><span class="skeleton">00:00</span></span><span class="tile-sub" id="q-last-sub">&nbsp;</span></div>
  </div>
  <div class="citybar" style="margin-bottom:16px">
    <div class="chips" role="group" aria-label="Büyüklük filtresi">
      <button class="chip q-min" type="button" data-min="0" aria-pressed="true">Tümü</button>
      <button class="chip q-min" type="button" data-min="2" aria-pressed="false">2,0 ve üzeri</button>
      <button class="chip q-min" type="button" data-min="3" aria-pressed="false">3,0 ve üzeri</button>
      <button class="chip q-min" type="button" data-min="4" aria-pressed="false">4,0 ve üzeri</button>
    </div>
    <div class="field" style="flex:0 1 280px"><label for="q-search" class="sr-only">Yer ara</label><input class="input" id="q-search" type="search" placeholder="İl ya da ilçe ara…" style="height:40px"></div>
  </div>
  <div class="table-wrap"><table>
    <thead><tr><th>Büyüklük</th><th style="text-align:left">Yer</th><th>Saat</th></tr></thead>
    <tbody id="q-body"><tr><td colspan="3" class="muted" style="text-align:center">Yükleniyor…</td></tr></tbody>
  </table></div>

  <div class="prose">
    <h2>Büyüklük ve şiddet aynı şey değil</h2>
    <p><strong>Büyüklük</strong>, depremin kaynağında açığa çıkan enerjinin ölçüsüdür ve her deprem için tek bir değerdir. Listedeki sayı budur. <strong>Şiddet</strong> ise depremin belirli bir yerde ne kadar hissedildiğini ve ne kadar hasar verdiğini anlatır; merkez üssünden uzaklaştıkça azalır. Aynı deprem bir ilde şiddetli, 200 kilometre ötede hafif hissedilebilir.</p>
    <p>Büyüklük ölçeği logaritmiktir. Büyüklükteki her bir birimlik artış, yer hareketinin yaklaşık 10 kat, açığa çıkan enerjinin ise yaklaşık 32 kat büyümesi demektir. Yani 6 büyüklüğündeki bir deprem, 4 büyüklüğündekinden yaklaşık bin kat fazla enerji açığa çıkarır.</p>
    <h2>Büyüklüklere göre kabaca ne beklenir?</h2>
    <ul>
      <li><strong>3,0'ın altı:</strong> Genellikle hissedilmez, yalnızca cihazlar kaydeder. Türkiye'de her gün onlarca kez olur.</li>
      <li><strong>3,0 – 3,9:</strong> Merkeze yakın yerlerde hafifçe hissedilir, hasar beklenmez.</li>
      <li><strong>4,0 – 4,9:</strong> Geniş bir alanda hissedilir, eşyalar sallanır; hasar nadirdir.</li>
      <li><strong>5,0 – 5,9:</strong> Dayanıksız yapılarda hasara yol açabilir.</li>
      <li><strong>6,0 ve üzeri:</strong> Yerleşim yerlerine yakınsa ciddi hasar ve can kaybına neden olabilir.</li>
    </ul>
    <h2>Derinlik neden önemli?</h2>
    <p>Derinlik, depremin yerin kaç kilometre altında başladığını gösterir. Sığ depremler (yaklaşık 0–20 km) enerjilerini yüzeye yakın boşalttıkları için aynı büyüklükteki derin depremlere göre daha kuvvetli hissedilir ve daha çok hasar verir. Türkiye'deki depremlerin çoğu sığdır.</p>
    <h2>Kandilli ve AFAD verileri neden farklı olabilir?</h2>
    <p>Türkiye'de depremleri iki kurum izler: Boğaziçi Üniversitesi <strong>Kandilli Rasathanesi</strong> ve <strong>AFAD</strong>. İkisi farklı istasyon ağları ve hesaplama yöntemleri kullandığı için aynı depremin büyüklüğü ve yeri küçük farklarla açıklanabilir. İlk dakikalarda verilen değerler, daha fazla istasyon verisi geldikçe güncellenir. Bu sayfa Kandilli'nin listesini gösterir.</p>
    <h2>Deprem anında ve sonrasında</h2>
    <ul>
      <li>Sarsıntı sırasında <strong>çök, kapan, tutun</strong>: sağlam bir eşyanın yanına çök, başını ve enseni koru, sarsıntı bitene kadar yerinden kalkma.</li>
      <li>Merdivenlere, balkona ve asansöre yönelme; camlardan ve devrilebilecek eşyalardan uzak dur.</li>
      <li>Sarsıntı bittikten sonra gaz, elektrik ve su vanalarını kapat, binayı sakin biçimde terk et.</li>
      <li>Acil durumda <strong>112</strong>'yi ara. Hatları meşgul etmemek için yakınlarınla kısa mesajla ya da internet üzerinden haberleş.</li>
      <li>Evde bir deprem çantası bulundur: su, dayanıklı yiyecek, el feneri, düdük, ilk yardım malzemesi, powerbank ve önemli belgelerin kopyaları.</li>
    </ul>
    <h2>Sık sorulan sorular</h2>
  </div>
  {faq([
    ("Liste ne kadar güncel?", "Sayfa açık kaldığı sürece iki dakikada bir yenilenir. Kandilli bir depremi yayımladıktan kısa süre sonra burada da görünür; yine de birkaç dakikalık gecikme olabilir."),
    ("Az önce sallandık ama listede yok, neden?", "Bir depremin konumunun ve büyüklüğünün hesaplanıp yayımlanması birkaç dakika sürer. Biraz bekleyip sayfayı yenile. Çok küçük ya da çok uzak depremler listeye girmeyebilir."),
    ("“Harita” bağlantısı nereye gidiyor?", "Depremin merkez üssünü OpenStreetMap üzerinde yeni sekmede açar."),
    ("Resmî bilgi için nereye bakmalıyım?", "Hasar, uyarı ve toplanma alanı bilgileri için AFAD'ın ve valiliklerin resmî duyurularını takip et. Bu sayfa yalnızca bilgilendirme amaçlıdır."),
  ])}
</div></section>""" + other_tools("deprem"))

# ------------------------------------------------------------------ Namaz
PAGES["/namaz-vakitleri/"] = dict(page="namaz", title="Namaz vakitleri — İmsak, öğle, ikindi, akşam, yatsı saatleri",
    desc="Şehrini seç; bugünün namaz vakitlerini, sıradaki vakte kalan süreyi ve aylık vakit çizelgesini gör. Diyanet hesaplama yöntemiyle.",
    crumbs=[("/araclar/", "Araçlar"), (None, "Namaz vakitleri")],
    body=page_head("Namaz vakitleri", "Şehrini ya da ilçeni seç; bugünün vakitlerini ve ayın tamamını gör.") + f"""
<section class="section"><div class="wrap">
  {CITYBAR}
  <div id="pray-err"></div>
  <p class="tile-label" style="margin-bottom:12px;font-size:15px"><b style="color:var(--text)"><span id="pray-city">—</span> · <span id="pray-date"></span></b><span id="pray-hijri"></span></p>
  <div class="pray-grid" id="pray-grid"></div>
  <p class="note" id="pray-next" aria-live="off" style="margin-top:16px">Vakitler yükleniyor…</p>

  <h2 style="font-size:22px;line-height:28px;margin:40px 0 12px" id="pray-month-title">Aylık vakitler</h2>
  <div class="table-wrap"><table>
    <thead><tr><th>Gün</th><th>İmsak</th><th>Güneş</th><th>Öğle</th><th>İkindi</th><th>Akşam</th><th>Yatsı</th></tr></thead>
    <tbody id="pray-month"><tr><td colspan="7" class="muted" style="text-align:center">Yükleniyor…</td></tr></tbody>
  </table></div>

  <div class="prose">
    <h2>Vakitler neye göre belirlenir?</h2>
    <p>Namaz vakitleri güneşin gökyüzündeki konumuna göre hesaplanır. Bu yüzden her gün bir–iki dakika değişir ve doğudaki şehirlerde batıdakilerden daha erken girer. Türkiye'nin en doğusu ile en batısı arasında bir saatten fazla fark vardır.</p>
    <ul>
      <li><strong>İmsak:</strong> Tan yerinin ağarmaya başladığı andır. Sabah namazının vakti bu anda girer, oruç tutanlar için yeme içme sona erer.</li>
      <li><strong>Güneş:</strong> Güneşin doğduğu andır. Sabah namazının vakti bu anda çıkar.</li>
      <li><strong>Öğle:</strong> Güneşin gün içinde en yüksek noktasını geçip batıya doğru kaymaya başladığı andır.</li>
      <li><strong>İkindi:</strong> Bir cismin gölgesinin, kendi boyuna öğle vaktindeki gölgesinin eklenmesiyle bulunan uzunluğa ulaştığı andır.</li>
      <li><strong>Akşam:</strong> Güneşin battığı andır. Oruç bu vakitte açılır.</li>
      <li><strong>Yatsı:</strong> Batı ufkundaki kızıllığın kaybolduğu andır.</li>
    </ul>
    <h2>Hesaplama yöntemi</h2>
    <p>Bu sayfadaki vakitler, Diyanet İşleri Başkanlığı'nın kullandığı açı değerleriyle (imsak için 18°, yatsı için 17°) hesaplanır. Yine de Diyanet'in yayımladığı resmî takvimle arasında birkaç dakikalık fark olabilir; çünkü Diyanet, hesaplanan vakitlere ihtiyat payı (temkin süresi) ekler ve her il–ilçe için ayrı koordinat kullanır.</p>
    <p class="note">İftar ve imsak gibi dakikanın önemli olduğu durumlarda Diyanet İşleri Başkanlığı'nın resmî vakitlerini esas al.</p>
    <h2>Hicri takvim</h2>
    <p>Sayfada bugünün hicri tarihi de gösterilir. Hicri takvim ay yılına dayanır ve güneş yılından yaklaşık 11 gün kısadır. Bu nedenle Ramazan ayı ve dinî bayramlar her yıl miladi takvimde yaklaşık 11 gün öne gelir.</p>
    <h2>Sık sorulan sorular</h2>
  </div>
  {faq([
    ("İlçem için ayrı vakit görebilir miyim?", "Evet. Arama kutusuna ilçenin adını yaz ve listeden seç. Vakitler seçtiğin yerin koordinatına göre hesaplanır."),
    ("Geri sayım neye göre çalışıyor?", "Cihazının saatine göre çalışır. Farklı saat dilimindeki bir şehri seçtiysen geri sayım doğru olmayabilir; vakit saatleri ise o şehrin yerel saatine göredir."),
    ("Diyanet takvimiyle neden birkaç dakika fark var?", "Diyanet hesaplanan vakitlere ihtiyat payı ekler ve kendi koordinat listesini kullanır. Bu sayfa aynı açı değerlerini kullanır ama ihtiyat paylarını içermeyebilir."),
    ("Veri kaynağı nedir?", "Vakitler Aladhan servisinden, Diyanet İşleri Başkanlığı yöntemi seçilerek alınır."),
  ])}
</div></section>""" + other_tools("namaz"))

# ------------------------------------------------------------------ Kripto
PAGES["/kripto/"] = dict(page="kripto", title="Kripto para fiyatları — Bitcoin ve Ethereum kaç dolar, kaç TL?",
    desc="Bitcoin, Ethereum, Solana, XRP ve diğer büyük kripto paraların güncel dolar ve TL fiyatı ile 24 saatlik değişimi.",
    crumbs=[("/araclar/", "Araçlar"), (None, "Kripto para fiyatları")],
    body=page_head("Kripto para fiyatları", "En büyük on kripto paranın dolar ve TL fiyatı ile son 24 saatteki değişimi.",
        '<p class="updated"><span class="live-dot"></span><span id="c-updated">Yükleniyor…</span> · 2 dakikada bir yenilenir</p>') + f"""
<section class="section"><div class="wrap">
  <div class="table-wrap"><table>
    <thead><tr><th>Kripto para</th><th>Fiyat ($)</th><th>Fiyat (₺)</th><th>24 saat</th></tr></thead>
    <tbody id="c-body"><tr><td colspan="4" class="muted" style="text-align:center">Yükleniyor…</td></tr></tbody>
  </table></div>
  <div class="prose">
    <h2>Tablodaki fiyatlar ne anlama geliyor?</h2>
    <p>Kripto paraların tek bir resmî fiyatı yoktur. Her borsada alıcı ve satıcıların o anki emirlerine göre biraz farklı bir fiyat oluşur. Bu tablodaki değerler, çok sayıda borsanın fiyatlarının işlem hacmine göre ağırlıklandırılmış ortalamasıdır. Kullandığın borsada göreceğin fiyat bundan biraz farklı olabilir.</p>
    <p>TL fiyatı, dolar fiyatının güncel kurla çevrilmesiyle bulunur. Türkiye'deki borsalarda TL ile işlem gören çiftlerde fiyat, talebe bağlı olarak bu değerin biraz üstünde ya da altında olabilir.</p>
    <h2>Kripto paralar neden bu kadar oynak?</h2>
    <p>Kripto piyasası 7 gün 24 saat açıktır, toplam büyüklüğü hisse senedi ve döviz piyasalarına göre küçüktür ve fiyatlar büyük ölçüde beklentilere göre oluşur. Bu yüzden bir günde yüzde 5–10'luk hareketler olağandır; küçük hacimli paralarda bu oran çok daha yüksek olabilir.</p>
    <h2>Stabil kripto para (stablecoin) nedir?</h2>
    <p>Tablodaki Tether (USDT) gibi stabil kripto paralar, değerini dolara sabitlemeyi hedefler. Fiyatlarının 1 dolar civarında kalması beklenir; bu yüzden değişim sütununda sıfıra çok yakın değerler görürsün. Genellikle kripto borsalarında alım satım yaparken ara para birimi olarak kullanılırlar.</p>
    <h2>Dikkat edilmesi gerekenler</h2>
    <ul>
      <li>Kripto varlıklar yüksek risklidir; yatırdığın paranın tamamını kaybedebilirsin.</li>
      <li>“Garantili kazanç” vaat eden kişi ve platformlara itibar etme; bu vaatler dolandırıcılığın en yaygın işaretidir.</li>
      <li>Cüzdan şifreni ve kurtarma kelimelerini kimseyle paylaşma.</li>
      <li>İşlem yapacağın platformun Türkiye'de yetkili olup olmadığını kontrol et.</li>
    </ul>
    <h2>Sık sorulan sorular</h2>
  </div>
  {faq([
    ("Fiyatlar anlık mı?", "Fiyatlar sayfa açık kaldığı sürece iki dakikada bir yenilenir. Saniyelik borsa verisi değildir; hızlı hareketlerde borsadaki fiyatla arasında fark olabilir."),
    ("24 saatlik değişim neyi gösteriyor?", "Dolar fiyatının tam 24 saat önceki değerine göre yüzde olarak ne kadar değiştiğini gösterir."),
    ("Neden yalnızca on kripto para var?", "Sayfayı sade tutmak için en büyük ve en çok bilinen on kripto para listelenir."),
    ("Veri kaynağı nedir?", "Fiyatlar CoinGecko'dan alınır."),
  ])}
  <p class="note" style="max-width:760px">Bu sayfadaki bilgiler yatırım tavsiyesi değildir.</p>
</div></section>""" + other_tools("kripto"))

# ------------------------------------------------------------------ Tatil
PAGES["/resmi-tatiller/"] = dict(page="tatil", title="Resmî tatiller — Bu yıl ve gelecek yıl tatil günleri",
    desc="Türkiye'deki resmî tatil günleri: tarih, gün ve tatile kalan süre. Ramazan ve Kurban Bayramı tarihleri dahil.",
    crumbs=[("/araclar/", "Araçlar"), (None, "Resmî tatiller")],
    body=page_head("Resmî tatiller", "Bu yılın ve gelecek yılın resmî tatil günleri ile bir sonraki tatile kalan süre.") + f"""
<section class="section"><div class="wrap">
  <div class="card" style="margin-bottom:24px;display:flex;justify-content:space-between;gap:24px;align-items:center;flex-wrap:wrap">
    <div><p class="tile-label">Sıradaki resmî tatil</p><p class="tile-value wrap-ok" id="h-next-name" style="font-size:26px;line-height:32px"><span class="skeleton">Yükleniyor</span></p><p class="tile-sub" id="h-next-date">&nbsp;</p></div>
    <div style="text-align:right"><p class="tile-label" style="justify-content:flex-end">Kalan süre</p><p class="tile-value" id="h-next-left"><span class="skeleton">00 gün</span></p></div>
  </div>
  <div class="table-wrap"><table>
    <thead><tr><th>Tatil</th><th>Tarih</th><th>Gün</th><th>Kalan</th></tr></thead>
    <tbody id="h-body"><tr><td colspan="4" class="muted" style="text-align:center">Yükleniyor…</td></tr></tbody>
  </table></div>
  <div class="prose">
    <h2>Türkiye'deki resmî tatiller</h2>
    <p>Türkiye'de resmî tatiller iki gruba ayrılır: tarihi her yıl aynı olan <strong>ulusal bayram ve genel tatiller</strong> ile tarihi her yıl değişen <strong>dinî bayramlar</strong>.</p>
    <h3>Tarihi sabit olanlar</h3>
    <ul>
      <li><strong>1 Ocak:</strong> Yılbaşı</li>
      <li><strong>23 Nisan:</strong> Ulusal Egemenlik ve Çocuk Bayramı</li>
      <li><strong>1 Mayıs:</strong> Emek ve Dayanışma Günü</li>
      <li><strong>19 Mayıs:</strong> Atatürk'ü Anma, Gençlik ve Spor Bayramı</li>
      <li><strong>15 Temmuz:</strong> Demokrasi ve Millî Birlik Günü</li>
      <li><strong>30 Ağustos:</strong> Zafer Bayramı</li>
      <li><strong>29 Ekim:</strong> Cumhuriyet Bayramı (28 Ekim öğleden sonra da tatildir)</li>
    </ul>
    <h3>Dinî bayramlar</h3>
    <ul>
      <li><strong>Ramazan Bayramı:</strong> Arife günü öğleden sonra başlar; toplam 3,5 gündür.</li>
      <li><strong>Kurban Bayramı:</strong> Arife günü öğleden sonra başlar; toplam 4,5 gündür.</li>
    </ul>
    <p>Dinî bayramlar hicri takvime göre belirlendiği için her yıl miladi takvimde yaklaşık 11 gün öne gelir. Bu yüzden bir yıl yaz ortasına denk gelen bayram, birkaç yıl sonra bahara kayar.</p>
    <h2>Tatil hafta sonuna denk gelirse ne olur?</h2>
    <p>Türkiye'de resmî tatil hafta sonuna denk geldiğinde, tatil kendiliğinden bir sonraki iş gününe aktarılmaz. Bazı yıllarda, bayram tatili hafta sonuyla birleşecek biçimde düştüğünde kamu çalışanları için aradaki günler idari izin sayılarak tatil uzatılabilir. Bu karar her seferinde ayrıca duyurulur ve özel sektör için bağlayıcı değildir.</p>
    <h2>Resmî tatilde çalışılırsa</h2>
    <p>İş Kanunu'na göre ulusal bayram ve genel tatil günlerinde çalışıp çalışmamak sözleşmeyle belirlenir. Çalışılmayan tatil günü için ücret tam ödenir; çalışılması hâlinde çalışana, her tatil günü için ayrıca bir günlük ücret daha ödenir. Kendi durumun için iş sözleşmene ve işyerindeki uygulamaya bak.</p>
    <h2>Sık sorulan sorular</h2>
  </div>
  {faq([
    ("Liste hangi yılları kapsıyor?", "İçinde bulunduğumuz yılın tüm tatillerini ve gelecek yılın tatillerini gösterir. Sıradaki tatil tabloda vurgulanır."),
    ("Yarım günlük tatiller listede var mı?", "Arife günleri ve 28 Ekim öğleden sonrası gibi yarım günlük tatiller kaynakta ayrı satır olarak yer almayabilir. Yukarıdaki açıklamada hangi tatillerin yarım günle başladığını görebilirsin."),
    ("Okul tatilleri de var mı?", "Hayır. Bu sayfa yalnızca resmî tatilleri gösterir; ara tatil ve yarıyıl tatili tarihleri için Millî Eğitim Bakanlığı'nın çalışma takvimine bak."),
    ("Veri kaynağı nedir?", "Tarihler Nager.Date açık veri servisinden alınır. Dinî bayram tarihlerinde, resmî duyuruyla arasında bir günlük fark olursa resmî duyuruyu esas al."),
  ])}
</div></section>""" + other_tools("tatil"))

# ------------------------------------------------------------------ Projeler
PAGES["/projeler/"] = dict(page="projeler", title="Oyunlar ve projeler — Abyss Diver, LexiRace, Spythere ve diğerleri",
    desc="Kanan Rahimov'un tarayıcıda ücretsiz oynanan oyunları ve web uygulamaları: Abyss Diver, LexiRace, Spythere, QR Car Connect, Nebula Drift ve daha fazlası.",
    crumbs=[(None, "Projeler")],
    body=page_head("Oyunlar ve projeler", "İndirmeden, tarayıcıda açılan oyunlar ve uygulamalar. Bir karta dokununca proje yeni sekmede açılır.") + f"""
<section class="section"><div class="wrap"><div class="grid g3">{project_cards()}</div>
<div class="prose">
  <h2>Abyss Diver</h2>
  <p>Abyss Diver, eski cep telefonlarındaki dalış oyunlarından ilham alan iki boyutlu bir macera oyunu. Bir dalgıcı yöneterek okyanusun derinliklerine iniyor, her bölümde farklı bir haritada yolunu buluyorsun. Oyunda 50 bölüm var; her bölüm bir öncekinden farklı tasarlandı ve zorluk kademeli olarak artıyor. Piksel grafiklerle hazırlandı, telefonda ve bilgisayarda tarayıcıdan oynanıyor.</p>
  <h2>LexiRace</h2>
  <p>LexiRace, İngilizce kelime dağarcığını geliştirmek isteyen Türkçe konuşanlar için bir kelime yarışı. Oyun alfabenin harflerini sırayla dolaşıyor: ekranda bir kelimenin Türkçe tanımını görüyorsun ve o harfle başlayan doğru İngilizce kelimeyi süre dolmadan sesli söylüyorsun. Cevaplar tarayıcının konuşma tanıma özelliğiyle algılanıyor; yani telaffuz da pratiğin parçası.</p>
  <p>Kelimeler A1'den C2'ye kadar seviyelere ayrılmış durumda. Günde bir kez oynanan günlük görev, harfin kelimenin başında, ortasında ya da sonunda olabildiği Zorlu Mod, bire bir düello ve Türkçe–İngilizce eşleştirmeye dayanan Word Match mini oyunu var. Kaçırdığın kelimeleri tekrar kartlarına ekleyip sonradan çalışabilirsin. Oyun özellikle telefonda oynanmak üzere tasarlandı.</p>
  <h2>Spythere</h2>
  <p>Spythere, arkadaş grubuyla oynanan bir parti oyunu. Her oyuncu kendi telefonundan odaya katılıyor. Oyunculara gizli bir konum gösteriliyor; yalnızca casus bu konumu bilmiyor. Oyuncular birbirlerine konumla ilgili sorular soruyor: casus kendini ele vermeden konumu anlamaya, diğerleri ise casusu bulmaya çalışıyor. Oyun, herkesin kimin casus olduğuna dair oy kullanmasıyla bitiyor.</p>
  <h2>QR Car Connect</h2>
  <p>QR Car Connect, araç sahipleri için bir iletişim çözümü. Aracının camına yapıştırdığın QR etiketini okutan kişi, telefon numaranı görmeden sana ulaşabiliyor; örneğin aracın birinin önünü kapattığında. Etiketler 10×5 cm boyutunda, yatay ve dikey seçenekleriyle geliyor. İsteyenler kendi arka plan görselini yükleyip etiketini kendisi tasarlayabiliyor.</p>
  <h2>Diğer projeler</h2>
  <p>Nebula: Infinite Drift neon görünümlü bir uzay oyunu, Magma Runner hızlı tempolu bir koşu oyunu, Guess the Number ise kısa molalar için bir sayı tahmin oyunu. Flamenear ve Luna Candles, arayüz tasarımı denemeleri olarak hazırlanmış prototipler.</p>
</div></div></section>""")

# ------------------------------------------------------------------ Hakkında
PAGES["/hakkinda/"] = dict(page="hakkinda", title="Hakkında — Rahimov",
    desc="rahimov.tr'yi kim yapıyor, sitede neler var ve veriler nereden geliyor.",
    crumbs=[(None, "Hakkında")],
    body=page_head("Hakkında", "rahimov.tr, günlük hayatta işe yarayan küçük araçları ve tarayıcı oyunlarını bir araya getiren kişisel bir site.") + """
<section class="section"><div class="wrap"><div class="prose">
  <h2>Kim yapıyor?</h2>
  <p>Ben Kanan Rahimov. Bağımsız çalışan bir geliştiriciyim; tarayıcıda çalışan oyunlar ve web uygulamaları yapıyorum. Bu site hem yaptığım projelerin adresi hem de kendim de sık kullandığım küçük araçların toplandığı yer.</p>
  <h2>Sitede neler var?</h2>
  <p><strong>Araçlar:</strong> Döviz kurları ve çevirici, altın fiyatları ve hesaplayıcı, hava durumu, son depremler, namaz vakitleri, kripto para fiyatları ve resmî tatiller. Hepsi ücretsizdir, üyelik istemez ve telefonda rahat kullanılacak biçimde tasarlandı.</p>
  <p><strong>Oyunlar ve projeler:</strong> Abyss Diver, LexiRace, Spythere, QR Car Connect ve diğerleri. Oyunlar tarayıcıda açılır; indirme gerekmez.</p>
  <h2>Nasıl bir anlayışla hazırlanıyor?</h2>
  <ul>
    <li><strong>Sade:</strong> Bir sayfayı açtığında aradığın bilgi en üstte olur. Açılır pencere ve gereksiz adım yoktur.</li>
    <li><strong>Kaynağı belli:</strong> Her aracın verisinin nereden geldiği sayfasında yazar.</li>
    <li><strong>Gizliliğe saygılı:</strong> Araçlar üyelik istemez. Şehir ve tema tercihin yalnızca kendi cihazında saklanır.</li>
    <li><strong>Önce telefon:</strong> Sayfalar ve oyunlar önce mobil ekran için düşünülür.</li>
  </ul>
  <h2>Veriler ve sorumluluk</h2>
  <p>Araçlardaki bilgiler açık veri kaynaklarından otomatik olarak alınır. Kaynaklarda gecikme ya da hata olabilir. Fiyat bilgileri yatırım tavsiyesi değildir; deprem, hava ve vakit bilgileri için resmî kurumların duyuruları esas alınmalıdır. Kaynakların tam listesi <a href="/araclar/">Araçlar</a> sayfasında.</p>
  <h2>İletişim</h2>
  <p>Hata bildirimi, öneri ya da iş birliği için <a href="/iletisim/">İletişim</a> sayfasına bakabilirsin.</p>
</div></div></section>""")

# ------------------------------------------------------------------ İletişim
PAGES["/iletisim/"] = dict(page="iletisim", title="İletişim — Rahimov",
    desc="rahimov.tr ile ilgili hata bildirimi, öneri ve iş birliği için iletişim bilgileri.",
    crumbs=[(None, "İletişim")],
    body=page_head("İletişim", "Bir hata mı buldun, bir önerin mi var? Aşağıdaki yollardan ulaşabilirsin.") + """
<section class="section"><div class="wrap"><div class="prose">
  <h2>E-posta</h2>
  <p>Hata bildirimi, öneri, iş birliği ve gizlilik talepleri için: <a href="mailto:destek.rahimov@gmail.com">destek.rahimov@gmail.com</a></p>
  <h2>GitHub</h2>
  <p>Projelerin çoğunun kaynak kodu GitHub'da. Hata bildirimi ve öneriler için ilgili projenin sayfasında yeni bir kayıt (issue) açabilirsin: <a href="https://github.com/rahimov0" target="_blank" rel="noopener">github.com/rahimov0</a></p>
  <ul>
    <li>Bu site: <a href="https://github.com/rahimov0/rahimov-tr/issues" target="_blank" rel="noopener">rahimov-tr</a></li>
    <li>Abyss Diver: <a href="https://github.com/rahimov0/abyss-diver/issues" target="_blank" rel="noopener">abyss-diver</a></li>
    <li>LexiRace: <a href="https://github.com/rahimov0/LEXIRACE/issues" target="_blank" rel="noopener">LEXIRACE</a></li>
    <li>Spythere: <a href="https://github.com/rahimov0/spythere/issues" target="_blank" rel="noopener">spythere</a></li>
  </ul>
  <h2>Hata bildirirken</h2>
  <p>Sorunu hızlı çözebilmem için şunları yazman yeterli:</p>
  <ul>
    <li>Hangi sayfada ya da oyunda olduğu</li>
    <li>Ne yaptığında ortaya çıktığı ve ne olmasını beklediğin</li>
    <li>Kullandığın cihaz ve tarayıcı (örneğin “Android, Chrome”)</li>
    <li>Varsa bir ekran görüntüsü</li>
  </ul>
  <h2>Veri hataları</h2>
  <p>Araçlardaki fiyat, hava, deprem ve vakit bilgileri üçüncü taraf kaynaklardan otomatik olarak alınır. Bir değerin yanlış göründüğünü düşünüyorsan hangi sayfada, hangi saatte ve hangi değeri gördüğünü yazarsan kaynağı kontrol edebilirim.</p>
  <h2>Gizlilik talepleri</h2>
  <p>Hesap gerektiren oyunlardaki verilerinin silinmesi gibi talepler için de aynı yoldan ulaşabilirsin. Ayrıntılar <a href="/gizlilik/">Gizlilik Politikası</a> sayfasında.</p>
</div></div></section>""")

# ------------------------------------------------------------------ Gizlilik
PAGES["/gizlilik/"] = dict(page="gizlilik", title="Gizlilik Politikası — Rahimov",
    desc="rahimov.tr ve alt alan adlarındaki projeler için gizlilik politikası, çerezler, konum izni ve Google AdSense reklamları hakkında bilgi.",
    crumbs=[(None, "Gizlilik Politikası")],
    body=page_head("Gizlilik Politikası", "Son güncelleme: 12 Kasım 2026") + """
<section class="section"><div class="wrap"><div class="prose">
  <p>Bu sayfa, <strong>rahimov.tr</strong> ve alt alan adlarında (ör. lexirace.rahimov.tr, spythere.rahimov.tr, abyss-diver.rahimov.tr) yayınlanan araç ve projelerde hangi bilgilerin işlendiğini açıklar. Siteyi kullanarak bu politikayı kabul etmiş olursun.</p>
  <h2>Toplanan bilgiler</h2>
  <p>Ana siteyi ve araçları kullanmak için hesap açman ya da kişisel bilgi vermen gerekmez.</p>
  <ul>
    <li><strong>Cihazda saklanan tercihler:</strong> Tema tercihin ve hava durumu ile namaz vakitleri için seçtiğin şehir, tarayıcının yerel depolamasında (localStorage) tutulur. Bu bilgiler cihazından bu sitenin sunucusuna gönderilmez.</li>
    <li><strong>Konum:</strong> “Konumumu kullan” düğmesine bastığında tarayıcın izin ister. İzin verirsen yaklaşık koordinatın, yalnızca hava durumu ya da namaz vakti sorgusu yapmak için ilgili veri sağlayıcısına gönderilir. Düğmeye basmadığın sürece konumun istenmez.</li>
    <li><strong>Hesap bilgileri:</strong> LexiRace gibi hesap gerektiren oyunlarda seçtiğin kullanıcı adı ve oyun ilerlemen saklanır. E-posta adresi istenmez.</li>
    <li><strong>Oyun verileri:</strong> Çok oyunculu oyunlarda (ör. Spythere) oda ve oyun durumu, oyun sürdüğü sürece sunucuda tutulur.</li>
    <li><strong>Mikrofon:</strong> LexiRace sesli cevap için tarayıcının konuşma tanıma özelliğini kullanır. Mikrofon izni yalnızca oyun sırasında kullanılır; ses kaydı bu site tarafından saklanmaz.</li>
  </ul>
  <h2>Üçüncü taraf veri sağlayıcıları</h2>
  <p>Araç sayfalarını açtığında tarayıcın, veriyi doğrudan aşağıdaki servislerden ister. Bu sırada her internet isteğinde olduğu gibi IP adresin ilgili servise iletilir. Servisler kendi gizlilik politikalarına tabidir.</p>
  <ul>
    <li>Truncgil Finans ve Frankfurter (döviz ve altın)</li>
    <li>Open-Meteo (hava durumu ve şehir araması)</li>
    <li>Kandilli Rasathanesi verisini sunan açık deprem servisi (depremler)</li>
    <li>Aladhan (namaz vakitleri)</li>
    <li>CoinGecko (kripto para fiyatları)</li>
    <li>Nager.Date (resmî tatiller)</li>
    <li>Google Fonts (yazı tipleri), Google Firebase (oyun hesapları ve çok oyunculu veriler)</li>
    <li>Barındırma sağlayıcıları (GitHub Pages, Vercel): sayfaları sunarken teknik kayıt tutabilir.</li>
  </ul>
  <h2>Çerezler ve Google AdSense reklamları</h2>
  <p>Bu sitede Google AdSense aracılığıyla reklam gösterilebilir.</p>
  <ul>
    <li>Google dahil üçüncü taraf sağlayıcılar, kullanıcının bu siteye veya internetteki başka sitelere yaptığı önceki ziyaretlere dayalı reklamlar göstermek için çerezleri kullanır.</li>
    <li>Google'ın reklam çerezlerini kullanması, Google ve iş ortaklarının kullanıcılara bu siteye ve/veya internetteki diğer sitelere yaptıkları ziyaretlere dayalı reklamlar sunmasını sağlar.</li>
    <li>Kişiselleştirilmiş reklamları <a href="https://adssettings.google.com" target="_blank" rel="noopener">Google Reklam Ayarları</a> sayfasından kapatabilirsin. Üçüncü taraf sağlayıcıların çerezlerini <a href="https://www.aboutads.info/choices" target="_blank" rel="noopener">aboutads.info</a> adresinden devre dışı bırakabilirsin.</li>
  </ul>
  <p>Google'ın verileri nasıl kullandığı hakkında daha fazla bilgi için: <a href="https://policies.google.com/technologies/partner-sites" target="_blank" rel="noopener">Google iş ortaklarının sitelerini veya uygulamalarını kullandığınızda Google'ın verileri nasıl kullandığı</a>.</p>
  <h2>Çocukların gizliliği</h2>
  <p>Bu site, bilerek 13 yaşından küçük çocuklardan kişisel bilgi toplamaz. Böyle bir bilginin toplandığını düşünüyorsan <a href="/iletisim/">İletişim</a> sayfasından ya da destek.rahimov@gmail.com adresinden ulaş, bilgiyi silelim.</p>
  <h2>Haklarınız</h2>
  <p>6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında, hakkında tutulan verilere erişme, düzeltilmesini veya silinmesini isteme hakkın var. Hesabının ve ilgili verilerin silinmesini istersen iletişime geçmen yeterli.</p>
  <h2>Değişiklikler</h2>
  <p>Bu politika zaman zaman güncellenebilir. Güncel sürüm her zaman bu sayfada yer alır ve en üstteki tarih değiştirilir.</p>
</div></div></section>""")

# ------------------------------------------------------------------ 404
PAGE_404 = layout("/404.html", "404", "Sayfa bulunamadı — Rahimov", "Aradığın sayfa bulunamadı.",
    page_head("Sayfa bulunamadı", "Aradığın sayfa taşınmış ya da hiç var olmamış olabilir.",
              '<div class="hero-actions"><a class="btn btn-primary" href="/">Ana sayfa</a><a class="btn btn-secondary" href="/araclar/">Araçlar</a></div>')
    + f'<section class="section"><div class="wrap"><div class="grid g3">{tool_cards()}</div></div></section>', noindex=True)


def write(rel, content):
    full = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        f.write(content)


def main():
    for path, p in PAGES.items():
        html = layout(path, p["page"], p["title"], p["desc"], p["body"], p.get("crumbs"))
        write((path.strip("/") + "/index.html").lstrip("/"), html)
    write("404.html", PAGE_404)
    write("gizlilik.html", f'<!DOCTYPE html><html lang="tr"><head><meta charset="UTF-8"><title>Gizlilik Politikası — Rahimov</title><link rel="canonical" href="{SITE}/gizlilik/"><meta http-equiv="refresh" content="0; url=/gizlilik/"></head><body><p><a href="/gizlilik/">Gizlilik Politikası</a></p></body></html>')
    urls = "".join(f"<url><loc>{SITE}{p}</loc><lastmod>{TODAY}</lastmod></url>\n" for p in PAGES)
    write("sitemap.xml", f'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n{urls}</urlset>\n')
    write("robots.txt", f"User-agent: *\nAllow: /\n\nSitemap: {SITE}/sitemap.xml\n")
    print("ok:", len(PAGES), "sayfa")


if __name__ == "__main__":
    main()

import json as _json
open("manifest.webmanifest","w",encoding="utf-8").write(_json.dumps({
  "name":"Rahimov — Günlük araçlar ve oyunlar","short_name":"Rahimov","lang":"tr",
  "start_url":"/","scope":"/","display":"standalone",
  "background_color":"#FAFAF7","theme_color":"#1A1917",
  "icons":[
    {"src":"/icons/icon-192.png","sizes":"192x192","type":"image/png","purpose":"any"},
    {"src":"/icons/icon-512.png","sizes":"512x512","type":"image/png","purpose":"any"},
    {"src":"/icons/icon-maskable-512.png","sizes":"512x512","type":"image/png","purpose":"maskable"}]},
  ensure_ascii=False,indent=2))
