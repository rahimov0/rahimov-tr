# rahimov.tr — DESIGN.md

Yön: sakin, düzenli bir "uygulama rafı". Arayüz nötr kalır, rengi her projenin kendi logosu taşır.
Mevcut sayfadaki aurora arka plan, cam efekti, emoji ikonlar, gradient başlık ve özel imleç kaldırıldı.
(Gerçek site örnekleriyle karşılaştırılmadı; UXKIN bağlı değildi.)

## Renk
| Token | Açık | Koyu | Rol |
|---|---|---|---|
| --bg | #FAFAF7 | #0C0C0B | sayfa zemini |
| --surface | #FFFFFF | #161614 | kartlar |
| --surface-2 | #F3F2EE | #1F1F1C | çipler, input, hover zemin |
| --border | #E7E5DF | #2A2926 | kenarlıklar |
| --text | #1A1917 | #F2F1EC | ana metin, başlıklar |
| --text-2 | #57534E | #A8A49C | açıklama metni |
| --text-3 | #6B6560 | #8C877F | meta, alan adları |
| --primary | #1A1917 | #F2F1EC | ana butonlar (zıt renk metinle) |
| --accent | #C2410C | #FB923C | linkler, "Yeni" rozeti, odak halkası |

Kontrast: metinler ≥ 4.5:1. Logolar dışında başka renk yok.

## Tipografi
- Başlık: Bricolage Grotesque 700/800 · Gövde: Geist 400/500/600
- Ölçek (px / satır yüksekliği): 13/18 · 14/20 · 16/26 · 18/28 · 22/28 · 28/34 · 40/44 · 56/58 (hero, clamp)
- Gövde 16px, satır en fazla ~68 karakter

## Boşluk
4 tabanlı: 4, 8, 12, 16, 24, 32, 48, 64, 96. Bölüm arası 96 (mobilde 64). İçerik genişliği 1200px.

## Şekil ve derinlik
Yarıçap: 8 (çip, input), 12 (buton), 20 (kart). Logo karesi: kenarın %23'ü.
Gölge: yalnızca kart hover'ında `--shadow-hover`.

## Bileşenler
- Buton: birincil (--primary zemin), ikincil (kenarlıklı), sessiz (sadece metin). Hover, :focus-visible (2px --accent halka), disabled.
- Proje kartı: logo 56px + ad + kategori·alan adı, 2–3 cümle açıklama, etiket çipleri, "Aç →". Kartın tamamı tıklanır.
- Filtre çipleri (sayılı) + arama kutusu. Boş sonuç durumu var.
- Nav: marka + bölüm linkleri + tema düğmesi. Footer: telif, gizlilik, GitHub.

## Görseller ve ikonlar
Her projenin kendi SVG logosu (64×64, yuvarlatılmış kare). Gerçek logo dosyası varsa SVG'nin yerine `<img>` konabilir.
Arayüz ikonları: 1.75px çizgili, tek set, emoji yok.
