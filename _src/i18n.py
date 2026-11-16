"""Çok dilli üretim: Türkçe HTML'den çeviri birimlerini çıkarır ve katalogla diğer dillere çevirir."""
import re, json, os
from bs4 import BeautifulSoup, NavigableString, Comment, Doctype

BLOCK = {"p", "li", "h1", "h2", "h3", "summary", "dt", "dd", "label", "th", "option", "title", "button", "figcaption"}
SKIP = {"script", "style", "svg", "code", "noscript"}
ATTRS = ("title", "alt", "aria-label", "placeholder")
LETTER = re.compile(r"[A-Za-zÇĞİÖŞÜçğıöşüÂâÎîÛû]")
KEEP_PREFIX = ("/assets/", "/icons/", "/logos/", "/favicon", "/manifest", "/ads.txt", "/robots", "/sitemap")
LANGS = ["en", "ru", "az"]
SITE = "https://rahimov.tr"


def norm(s):
    return re.sub(r"\s+", " ", s).strip()


def _inside(el, names):
    p = el.parent
    while p is not None and getattr(p, "name", None):
        if p.name in names:
            return True
        p = p.parent
    return False


INLINE_OK = {"strong", "b", "em", "a", "br", "i"}


def is_unit(el):
    """Blok, yalnızca basit satır içi biçim içeriyorsa tek parça çevrilir (id'li/dinamik öğe, svg, form yoksa)."""
    kids = [c for c in el.children if getattr(c, "name", None)]
    if len(kids) == 1 and norm(kids[0].get_text()) == norm(el.get_text()):
        return False
    for d in el.find_all(True):
        if d.name not in INLINE_OK and not (d.name == "span" and not d.get("id") and not d.get("class")):
            return False
        if d.get("id"):
            return False
    return True


def units(soup):
    """(tür, düğüm, metin) üretir: 'block' iç HTML, 'text' tek metin düğümü, 'attr' öznitelik."""
    out = []
    chosen = set()
    for el in soup.find_all(True):
        if el.name in SKIP or _inside(el, SKIP) or el.get("translate") == "no" or el.find_parent(attrs={"translate": "no"}):
            continue
        for a in ATTRS:
            v = el.get(a)
            if v and LETTER.search(v):
                out.append(("attr", (el, a), norm(v)))
        if el.name == "meta" and el.get("name") in ("description",) or el.name == "meta" and el.get("property") in ("og:title", "og:description"):
            out.append(("attr", (el, "content"), norm(el.get("content", ""))))
        if el.name in BLOCK and not el.find(BLOCK) and not _inside(el, BLOCK) and is_unit(el):
            h = norm(el.decode_contents())
            if LETTER.search(el.get_text()):
                out.append(("block", el, h))
                chosen.add(id(el))
    for t in soup.find_all(string=True):
        if isinstance(t, (Comment, Doctype)) or not LETTER.search(t):
            continue
        if t.parent is not None and (t.parent.get("translate") == "no" or t.find_parent(attrs={"translate": "no"})):
            continue
        if _inside(t, SKIP):
            continue
        p, inside = t.parent, False
        while p is not None and getattr(p, "name", None):
            if id(p) in chosen:
                inside = True
                break
            p = p.parent
        if inside:
            continue
        out.append(("text", t, norm(str(t))))
    return out


def tagsig(h):
    return sorted(re.findall(r"<\s*([a-zA-Z0-9]+)", h))


def localize(html, lang, cat, missing):
    soup = BeautifulSoup(html, "html.parser")
    for kind, node, src in units(soup):
        tr = cat.get(src)
        if tr is None:
            missing.add(src)
            continue
        if kind == "attr":
            el, a = node
            el[a] = tr
        elif kind == "block":
            if tagsig(tr) != tagsig(src):
                missing.add("!TAG " + src)
                continue
            node.clear()
            node.append(BeautifulSoup(tr, "html.parser"))
        else:
            t = str(node)
            lead = t[: len(t) - len(t.lstrip())]
            trail = t[len(t.rstrip()):]
            node.replace_with(NavigableString(lead + tr + trail))
    # bağlantılar dil önekine
    for el in soup.find_all(href=True):
        h = el["href"]
        if el.get("data-noloc") is not None:
            continue
        if el.name == "link" and "canonical" in (el.get("rel") or []):
            el["href"] = h.replace(SITE + "/", SITE + "/" + lang + "/", 1)
            continue
        if el.name == "link" and el.get("rel") and ("alternate" in el["rel"] or "canonical" in el["rel"] or "manifest" in el["rel"] or "icon" in el["rel"] or "apple-touch-icon" in el["rel"] or "stylesheet" in el["rel"] or "preconnect" in el["rel"]):
            continue
        if h.startswith("/") and not h.startswith("//") and not h.startswith(KEEP_PREFIX):
            el["href"] = "/" + lang + h
    for m in soup.find_all("meta", property="og:url"):
        m["content"] = m["content"].replace(SITE + "/", SITE + "/" + lang + "/", 1)
    lc = soup.find(id="langCur")
    if lc is not None:
        lc.string = lang.upper()
    for a in soup.select(".langsw-menu a"):
        if a.get("data-lang") == lang:
            a["aria-current"] = "true"
        elif a.get("aria-current"):
            del a["aria-current"]
    soup.html["lang"] = lang
    return str(soup)


def extract(pages_html):
    seen, order = set(), []
    for html in pages_html:
        soup = BeautifulSoup(html, "html.parser")
        for kind, node, src in units(soup):
            if src not in seen:
                seen.add(src)
                order.append(src)
    return order


def load_cat(root, lang):
    p = os.path.join(root, "_src", "i18n", lang + ".json")
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else {}
