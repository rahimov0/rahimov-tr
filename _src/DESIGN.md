# rahimov.tr — tasarım sistemi (v2, fütüristik)

Yön: koyu varsayılan, ızgara + yumuşak parıltı zemin, camsı yüzeyler, mono etiketler. Açık tema isteğe bağlı (`data-theme="light"`).

## Renk (roller)
- bg #05070B · surface beyaz %3.5 · surface-2 beyaz %6.5 · border beyaz %9
- text #EEF3F8 · text-2 #A7B3C2 · text-3 #8392A5
- accent (birincil: düğme, vurgu, bağlantı) #22D3EE · accent-2 (logo noktası, sıcak vurgu) #FB923C
- up #34D399 · down #FB7185
- Açık tema: bg #F3F6FA, accent #0E7490

## Yazı
- Başlık: Space Grotesk 700, sıkı iz (-0.03em)
- Gövde: Geist 400/500/600
- Etiket/sayı: JetBrains Mono (kicker, tablo başlığı, şerit, panel). Gradyanlı yazı yok.

## Şekil ve derinlik
- Radius 8 / 12 / 18 / panel 20. Gölge yerine ince parıltı (`--glow`) yalnızca hover ve panelde.

## Bileşenler
- Kayan şerit (marquee): sonsuz, ~55 px/sn, hover'da durur, reduced-motion'da kaydırılabilir liste.
- Canlı panel (hero): 6 fiyat + 30 günlük USD/TRY çizgisi.
- Kartlar camsı, hover'da accent çerçeve. Bölüm başlıklarında mono "01 — ÖZET" etiketi.
