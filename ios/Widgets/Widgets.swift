import WidgetKit
import SwiftUI

// MARK: - Renkler (sitedeki bento paleti)

extension Color {
    init(light: UInt, dark: UInt) {
        self = Color(UIColor { tc in
            let v = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
        })
    }
    static let fxBg = Color(light: 0xE6EFE6, dark: 0x18241C)
    static let wxBg = Color(light: 0xE1ECF7, dark: 0x152130)
    static let panelBg = Color(light: 0xF2EFE8, dark: 0x121110)
    static let ink = Color(light: 0x1B1A17, dark: 0xF2EEE6)
    static let ink2 = Color(light: 0x57524A, dark: 0xB5AFA4)
    static let up = Color(light: 0x1D7A48, dark: 0x5CC58C)
    static let down = Color(light: 0xC0352E, dark: 0xF27A71)
}

/// Namaz kutusu: vakte göre gökyüzü rengi (sitedeki gibi). Ramazan'da sıcak gün batımı.
func skyGradient(_ phase: Int, ramadan: Bool) -> LinearGradient {
    let pairs: [(UInt, UInt)] = [(0x0D1424, 0x26335C), (0x1E1B3A, 0xC9755A), (0x2D3A6B, 0xF0B072), (0x1F5D93, 0x3E8BC6), (0x2E5578, 0xC08A4A), (0x3A1E4C, 0xB5523A)]
    let p = ramadan ? (0x2A1640 as UInt, 0x8C3B2E as UInt) : pairs[max(0, min(5, phase))]
    func c(_ v: UInt) -> Color { Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255) }
    return LinearGradient(colors: [c(p.0), c(p.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct ChangeText: View {
    let v: Double
    var body: some View {
        Text((v > 0 ? "▲ " : v < 0 ? "▼ " : "") + Fmt.pct(v))
            .font(.caption2.weight(.bold)).foregroundStyle(v > 0 ? Color.up : v < 0 ? Color.down : Color.ink2)
    }
}

// MARK: - Namaz

struct PrayerState {
    var city: String
    var day: PrayerDay?
    var targetName: String
    var target: Date?
    var nextIndex: Int
    var phase: Int
    var ramadan: Bool
    var hijri: String

    static func compute(days: [PrayerDay], at now: Date, city: String) -> PrayerState {
        guard let today = days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: now) }) ?? days.first else {
            return PrayerState(city: city, day: nil, targetName: T("Vakitler alınamadı"), target: nil, nextIndex: -1, phase: 0, ramadan: false, hijri: "")
        }
        let tomorrow = days.first { $0.date > today.date }
        var idx = today.times.firstIndex { $0 > now } ?? -1
        var target: Date? = idx >= 0 ? today.times[idx] : tomorrow?.times.first
        if idx < 0 { idx = 0 }
        let phase = (idx + 5) % 6   // sıradakinden bir önceki vakit = şu anki dönem
        // Ramazan: imsak–akşam arası iftara, akşamdan sonra sahura (yarın imsak) sayılır
        let ramadanNow = today.hijriMonth == 9 || (tomorrow?.hijriMonth == 9 && now > today.times[4])
        var name = String(format: T("%@ vaktine"), Prayer(rawValue: idx)!.name)
        if ramadanNow {
            let iftar = today.times[4], imsak = today.times[0]
            if today.hijriMonth == 9 && now >= imsak && now < iftar { target = iftar; name = T("İftara") }
            else { target = now < imsak ? imsak : tomorrow?.times.first; name = T("Sahura (imsak)") }
        }
        let hijri = today.hijriMonth == 9 ? String(format: T("Ramazan'ın %d. günü"), today.hijriDay) : ""
        return PrayerState(city: city, day: today, targetName: name, target: target, nextIndex: idx, phase: phase, ramadan: ramadanNow, hijri: hijri)
    }
}

struct NamazEntry: TimelineEntry { let date: Date; let s: PrayerState }

struct NamazProvider: TimelineProvider {
    func placeholder(in context: Context) -> NamazEntry { NamazEntry(date: Date(), s: sample()) }
    func getSnapshot(in context: Context, completion: @escaping (NamazEntry) -> Void) { completion(placeholder(in: context)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NamazEntry>) -> Void) {
        Task {
            let city = Store.city
            let days = (try? await API.prayerDays(city, days: 3)) ?? []
            let now = Date()
            var points = [now]
            for d in days { points += d.times.filter { $0 > now } }
            points = Array(points.sorted().prefix(14))
            let entries = points.map { NamazEntry(date: $0, s: PrayerState.compute(days: days, at: $0.addingTimeInterval(1), city: city.name)) }
            let next = days.isEmpty ? now.addingTimeInterval(1800) : (points.last ?? now).addingTimeInterval(60)
            completion(Timeline(entries: entries.isEmpty ? [placeholder(in: context)] : entries, policy: .after(next)))
        }
    }
    func sample() -> PrayerState {
        let now = Date(), cal = Calendar.current
        let base = cal.startOfDay(for: now)
        let t = [6.2, 7.7, 12.9, 15.5, 17.9, 19.3].map { base.addingTimeInterval($0 * 3600) }
        let day = PrayerDay(date: base, times: t, hijriMonth: 5, hijriDay: 1, hijriYear: "1448")
        return PrayerState.compute(days: [day], at: now, city: Store.city.name)
    }
}

struct NamazView: View {
    @Environment(\.widgetFamily) var family
    let e: NamazEntry
    var body: some View {
        let s = e.s
        switch family {
        case .accessoryInline:
            if let t = s.target { Text("\(s.targetName) \(t, style: .timer)") } else { Text(s.targetName) }
        case .accessoryCircular:
            VStack(spacing: 0) {
                Image(systemName: s.ramadan ? "moon.stars.fill" : "moon.fill").font(.caption)
                if let t = s.target { Text(t, style: .timer).font(.system(size: 11, weight: .bold)).monospacedDigit().multilineTextAlignment(.center) }
            }.containerBackground(for: .widget) { AccessoryWidgetBackground() }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(s.targetName).font(.caption.weight(.semibold))
                if let t = s.target { Text(t, style: .timer).font(.title3.weight(.bold)).monospacedDigit() }
                Text(s.city).font(.caption2).foregroundStyle(.secondary)
            }.containerBackground(for: .widget) { Color.clear }
        default:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(s.ramadan ? T("Ramazan") : T("Namaz")).font(.caption.weight(.bold))
                    Spacer()
                    Text(s.city).font(.caption2).lineLimit(1)
                }.foregroundStyle(.white.opacity(0.8))
                Text(s.targetName).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
                if let t = s.target {
                    Text(t, style: .timer).font(.system(size: family == .systemSmall ? 30 : 36, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(.white).minimumScaleFactor(0.6).lineLimit(1)
                }
                if !s.hijri.isEmpty { Text(s.hijri).font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.85)) }
                Spacer(minLength: 0)
                if family != .systemSmall, let d = s.day {
                    HStack(spacing: 4) {
                        ForEach(0..<6, id: \.self) { i in
                            VStack(spacing: 1) {
                                Text(Prayer(rawValue: i)!.name).font(.system(size: 9, weight: .medium)).lineLimit(1).minimumScaleFactor(0.7)
                                Text(Fmt.time(d.times[i])).font(.system(size: 12, weight: .bold)).monospacedDigit()
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 4)
                            .background(.white.opacity(i == s.nextIndex ? 0.28 : 0.1), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }.foregroundStyle(.white)
                } else if let d = s.day, s.nextIndex >= 0 {
                    Text("\(Prayer(rawValue: s.nextIndex)!.name) \(Fmt.time(d.times[s.nextIndex]))").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
                }
            }
            .containerBackground(for: .widget) { skyGradient(s.phase, ramadan: s.ramadan) }
        }
    }
}

struct NamazWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "namaz", provider: NamazProvider()) { e in
            NamazView(e: e).widgetURL(URL(string: "rahimov://namaz"))
        }
        .configurationDisplayName(T("Namaz vakti"))
        .description(T("Sıradaki vakte geri sayım; Ramazan'da iftar ve sahur."))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Döviz

struct MarketEntry: TimelineEntry { let date: Date; let m: Market }

struct MarketProvider: TimelineProvider {
    func placeholder(in context: Context) -> MarketEntry { MarketEntry(date: Date(), m: API.cachedMarket ?? .placeholder) }
    func getSnapshot(in context: Context, completion: @escaping (MarketEntry) -> Void) { completion(placeholder(in: context)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MarketEntry>) -> Void) {
        Task {
            let m = (try? await API.market()) ?? API.cachedMarket ?? .placeholder
            completion(Timeline(entries: [MarketEntry(date: Date(), m: m)], policy: .after(Date().addingTimeInterval(20 * 60))))
        }
    }
}

struct RateRow: View {
    let label: String; let r: Rate?; let digits: Int
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Color.ink2).lineLimit(1)
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 0) {
                Text((r.map { Fmt.num($0.sell, digits) } ?? "—") + " ₺").font(.subheadline.weight(.bold)).monospacedDigit().foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.7)
                if let r { ChangeText(v: r.change) }
            }
        }
    }
}

struct MarketView: View {
    @Environment(\.widgetFamily) var family
    let e: MarketEntry
    var body: some View {
        let r = e.m.rates
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(T("Piyasa")).font(.caption.weight(.bold)).foregroundStyle(Color.ink2); Spacer(); Text(Fmt.time(e.date)).font(.caption2).foregroundStyle(Color.ink2) }
            if family == .systemSmall {
                Text(T("Dolar")).font(.caption.weight(.semibold)).foregroundStyle(Color.ink2)
                Text(Fmt.num(r["USD"]?.sell ?? 0, 2) + " ₺").font(.system(size: 26, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(Color.ink).minimumScaleFactor(0.6).lineLimit(1)
                if let u = r["USD"] { ChangeText(v: u.change) }
                Spacer(minLength: 0)
                RateRow(label: T("Gram altın"), r: r["GRA"], digits: 0)
            } else {
                RateRow(label: T("Dolar"), r: r["USD"], digits: 4)
                RateRow(label: T("Euro"), r: r["EUR"], digits: 4)
                RateRow(label: T("Gram altın"), r: r["GRA"], digits: 2)
                if family == .systemLarge {
                    RateRow(label: T("Sterlin"), r: r["GBP"], digits: 4)
                    RateRow(label: T("Çeyrek altın"), r: r["CEYREKALTIN"], digits: 2)
                    RateRow(label: T("Gümüş"), r: r["GUMUS"], digits: 2)
                }
            }
        }
        .containerBackground(for: .widget) { Color.fxBg }
    }
}

struct DovizWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "doviz", provider: MarketProvider()) { e in
            MarketView(e: e).widgetURL(URL(string: "rahimov://doviz"))
        }
        .configurationDisplayName(T("Döviz ve altın"))
        .description(T("Dolar, euro ve gram altın; yaklaşık 20 dakikada bir yenilenir."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Hava

struct WeatherEntry: TimelineEntry { let date: Date; let w: Weather; let city: String }

struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry { WeatherEntry(date: Date(), w: API.cachedWeather ?? .placeholder, city: Store.city.name) }
    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) { completion(placeholder(in: context)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        Task {
            let c = Store.city
            let w = (try? await API.weather(c)) ?? API.cachedWeather ?? .placeholder
            completion(Timeline(entries: [WeatherEntry(date: Date(), w: w, city: c.name)], policy: .after(Date().addingTimeInterval(30 * 60))))
        }
    }
}

struct WeatherView: View {
    @Environment(\.widgetFamily) var family
    let e: WeatherEntry
    var body: some View {
        let w = e.w
        VStack(alignment: .leading, spacing: 4) {
            Text(e.city).font(.caption.weight(.bold)).foregroundStyle(Color.ink2).lineLimit(1)
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: WX.symbol(w.code, day: w.isDay)).symbolRenderingMode(.multicolor).font(.system(size: family == .systemSmall ? 28 : 34))
                Text("\(Int(w.temp.rounded()))°").font(.system(size: family == .systemSmall ? 38 : 44, weight: .bold, design: .rounded)).foregroundStyle(Color.ink)
            }
            Text(WX.desc(w.code)).font(.caption.weight(.semibold)).foregroundStyle(Color.ink).lineLimit(1)
            Text("\(T("en düşük")) \(Int(w.min.rounded()))° · \(T("en yüksek")) \(Int(w.max.rounded()))°").font(.caption2).foregroundStyle(Color.ink2).lineLimit(1).minimumScaleFactor(0.8)
            if family != .systemSmall && !w.hours.isEmpty {
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    ForEach(Array(w.hours.prefix(6).enumerated()), id: \.offset) { _, h in
                        VStack(spacing: 2) {
                            Text(h.time).font(.system(size: 10)).foregroundStyle(Color.ink2)
                            Image(systemName: WX.symbol(h.code, day: true)).symbolRenderingMode(.multicolor).font(.caption)
                            Text("\(Int(h.temp.rounded()))°").font(.caption.weight(.bold)).foregroundStyle(Color.ink)
                        }.frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .containerBackground(for: .widget) { Color.wxBg }
    }
}

struct HavaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "hava", provider: WeatherProvider()) { e in
            WeatherView(e: e).widgetURL(URL(string: "rahimov://hava"))
        }
        .configurationDisplayName(T("Hava durumu"))
        .description(T("Şehrinin anlık hava durumu ve sonraki saatler."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Panel (hepsi bir arada)

struct PanelEntry: TimelineEntry { let date: Date; let m: Market; let w: Weather; let p: PrayerState }

struct PanelProvider: TimelineProvider {
    func placeholder(in context: Context) -> PanelEntry {
        PanelEntry(date: Date(), m: API.cachedMarket ?? .placeholder, w: API.cachedWeather ?? .placeholder, p: NamazProvider().sample())
    }
    func getSnapshot(in context: Context, completion: @escaping (PanelEntry) -> Void) { completion(placeholder(in: context)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PanelEntry>) -> Void) {
        Task {
            let c = Store.city
            async let m = try? API.market()
            async let w = try? API.weather(c)
            async let d = try? API.prayerDays(c, days: 2)
            let market = await m ?? API.cachedMarket ?? .placeholder
            let weather = await w ?? API.cachedWeather ?? .placeholder
            let days = await d ?? []
            let now = Date()
            var points = [now]
            for dd in days { points += dd.times.filter { $0 > now && $0 < now.addingTimeInterval(30 * 60) } }
            let entries = points.sorted().map { PanelEntry(date: $0, m: market, w: weather, p: PrayerState.compute(days: days, at: $0.addingTimeInterval(1), city: c.name)) }
            completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(30 * 60))))
        }
    }
}

struct PanelView: View {
    @Environment(\.widgetFamily) var family
    let e: PanelEntry
    var body: some View {
        let r = e.m.rates
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Namaz
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.p.targetName).font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
                    if let t = e.p.target { Text(t, style: .timer).font(.system(size: 22, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6) }
                    Spacer(minLength: 0)
                    Text(e.p.city).font(.caption2).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                }
                .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(skyGradient(e.p.phase, ramadan: e.p.ramadan), in: RoundedRectangle(cornerRadius: 14))
                // Hava
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: WX.symbol(e.w.code, day: e.w.isDay)).symbolRenderingMode(.multicolor)
                        Text("\(Int(e.w.temp.rounded()))°").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(Color.ink)
                    }
                    Spacer(minLength: 0)
                    Text(WX.desc(e.w.code)).font(.caption2).foregroundStyle(Color.ink2).lineLimit(1)
                }
                .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.wxBg, in: RoundedRectangle(cornerRadius: 14))
                if family == .systemMedium {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(T("Dolar")).font(.caption2.weight(.semibold)).foregroundStyle(Color.ink2)
                        Text(Fmt.num(r["USD"]?.sell ?? 0, 2)).font(.system(size: 20, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
                        Spacer(minLength: 0)
                        Text(T("Gram altın")).font(.caption2.weight(.semibold)).foregroundStyle(Color.ink2)
                        Text(Fmt.num(r["GRA"]?.sell ?? 0, 0)).font(.subheadline.weight(.bold)).monospacedDigit().foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
                    }
                    .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.fxBg, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            if family == .systemLarge {
                VStack(spacing: 4) {
                    RateRow(label: T("Dolar"), r: r["USD"], digits: 4)
                    RateRow(label: T("Euro"), r: r["EUR"], digits: 4)
                    RateRow(label: T("Sterlin"), r: r["GBP"], digits: 4)
                    RateRow(label: T("Çeyrek altın"), r: r["CEYREKALTIN"], digits: 2)
                    RateRow(label: T("Gram altın"), r: r["GRA"], digits: 2)
                }
                .padding(10).background(Color.fxBg, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .containerBackground(for: .widget) { Color.panelBg }
    }
}

struct PanelWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "panel", provider: PanelProvider()) { e in
            PanelView(e: e).widgetURL(URL(string: "rahimov://panel"))
        }
        .configurationDisplayName(T("Günlük panel"))
        .description(T("Namaz, hava ve döviz bir arada."))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct RahimovWidgets: WidgetBundle {
    var body: some Widget {
        PanelWidget()
        NamazWidget()
        DovizWidget()
        HavaWidget()
    }
}
