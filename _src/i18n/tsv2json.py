"""Tek seferlik: lang.tsv (sıra numaralı çeviri) -> lang.json (Türkçe kaynak anahtarlı). Sonra tsv silinir."""
import json, re, sys, os
D = os.path.dirname(os.path.abspath(__file__))
src = json.load(open(os.path.join(D, "strings.json"), encoding="utf-8"))
lang = sys.argv[1]
tr = {}
for line in open(os.path.join(D, lang + ".tsv"), encoding="utf-8"):
    line = line.rstrip("\n")
    if not line: continue
    i, t = line.split("\t", 1)
    tr[int(i)] = t
assert len(tr) == len(src), (len(tr), len(src))
sig = lambda h: sorted(re.findall(r"<\s*([a-zA-Z0-9]+)", h))
out, bad = {}, []
for i, s in enumerate(src):
    t = tr[i]
    if sig(t) != sig(s): bad.append((i, s[:60], t[:60]))
    out[s] = t
old = os.path.join(D, lang + ".json")
if os.path.exists(old):
    prev = json.load(open(old, encoding="utf-8")); prev.update(out); out = prev
json.dump(out, open(old, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
print(lang, len(out), "etiket uyuşmazlığı:", bad)
