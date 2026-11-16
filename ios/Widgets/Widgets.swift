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

extension Prayer {
    var symbol: String { ["moon.stars.fill", "sunrise.fill", "sun.max.fill", "sun.haze.fill", "sunset.fill", "moon.fill"][rawValue] }
}

struct PrayerState {
    var city: String
    var day: PrayerDay?
    var targetName: String
    var target: Date?
    var prev: Date?
    var nextIndex: Int
    var phase: Int
    var ramadan: Bool
    var hijri: String        // "Ramazan'ın 5. günü" (yalnız Ramazan'da)
    var hijriDate: String    // "7 Cemaziyelahir 1448"

    static func compute(days: [PrayerDay], at now: Date, city: String) -> PrayerState {
        guard let today = days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: now) }) ?? days.first else {
            return PrayerState(city: city, day: nil, targetName: T("Vakitler alınamadı"), target: nil, prev: nil, nextIndex: -1, phase: 0, ramadan: false, hijri: "", hijriDate: "")
        }
        let tomorrow = days.first { $0.date > today.date }
        var idx = today.times.firstIndex { $0 > now } ?? -1
        var target: Date? = idx >= 0 ? today.times[idx] : tomorrow?.times.first
        let lastPassed = today.times.last { $0 <= now }
        var prev: Date? = lastPassed ?? today.times.last.map { $0.addingTimeInterval(-86400) }
        if idx < 0 { idx = 0 }
        let phase = (idx + 5) % 6
        let ramadanNow = today.hijriMonth == 9 || (tomorrow?.hijriMonth == 9 && now > today.times[4])
        var name = String(format: T("%@ vaktine"), Prayer(rawValue: idx)!.name)
        if ramadanNow {
            let iftar = today.times[4], imsak = today.times[0]
            if today.hijriMonth == 9 && now >= imsak && now < iftar { target = iftar; prev = imsak; name = T("İftara") }
            else { target = now < imsak ? imsak : tomorrow?.times.first; prev = now < imsak ? today.times[4].addingTimeInterval(-86400) : iftar; name = T("Sahura (imsak)") }
        }
        let hijri = today.hijriMonth == 9 ? String(format: T("Ramazan'ın %d. günü"), today.hijriDay) : ""
        return PrayerState(city: city, day: today, targetName: name, target: target, prev: prev, nextIndex: idx, phase: phase, ramadan: ramadanNow, hijri: hijri, hijriDate: Hijri.date(today))
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
        let now = Date()
        let base = Calendar.current.startOfDay(for: now)
        let t = [6.2, 7.7, 12.9, 15.5, 17.9, 19.3].map { base.addingTimeInterval($0 * 3600) }
        let day = PrayerDay(date: base, times: t, hijriMonth: 6, hijriDay: 7, hijriYear: "1448")
        return PrayerState.compute(days: [day], at: now, city: Store.city.name)
    }
}

/// İki vakit arasındaki ilerleme (widget içinde kendiliğinden ilerler)
struct PrayerProgress: View {
    let s: PrayerState
    var body: some View {
        if let a = s.prev, let b = s.target, a < b {
            ProgressView(timerInterval: a...b, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                .progressViewStyle(.linear).tint(.white).background(.white.opacity(0.18), in: Capsule())
        }
    }
}

struct PrayerRow: View {
    let p: Prayer; let time: Date; let isNext: Bool; var big = false
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: p.symbol).font(.system(size: big ? 15 : 11, weight: .semibold)).frame(width: big ? 22 : 16)
                .symbolRenderingMode(.hierarchical)
            Text(p.name).font(.system(size: big ? 15 : 12, weight: isNext ? .bold : .medium)).lineLimit(1)
            Spacer(minLength: 4)
            Text(Fmt.time(time)).font(.system(size: big ? 16 : 12.5, weight: .bold)).monospacedDigit()
        }
        .padding(.horizontal, big ? 12 : 7).padding(.vertical, big ? 7 : 2.5)
        .background(.white.opacity(isNext ? 0.24 : 0), in: RoundedRectangle(cornerRadius: big ? 10 : 7))
        .foregroundStyle(.white.opacity(isNext ? 1 : 0.85))
    }
}

struct NamazView: View {
    @Environment(\.widgetFamily) var family
    let e: NamazEntry
    var nextTime: String {
        guard let d = e.s.day, e.s.nextIndex >= 0 else { return "" }
        return Fmt.time(e.s.target ?? d.times[e.s.nextIndex])
    }
    var body: some View {
        let s = e.s
        switch family {
        case .accessoryInline:
            Group {
                if let t = s.target { Text("\(s.targetName) \(t, style: .timer)") } else { Text(s.targetName) }
            }.containerBackground(for: .widget) { Color.clear }
        case .accessoryCircular:
            Group {
                if let a = s.prev, let b = s.target, a < b {
                    ProgressView(timerInterval: a...b, countsDown: true) {
                        Image(systemName: s.ramadan ? "moon.stars.fill" : (Prayer(rawValue: s.nextIndex)?.symbol ?? "moon.fill"))
                    } currentValueLabel: {
                        Text(nextTime).font(.system(size: 11, weight: .bold)).monospacedDigit()
                    }
                    .progressViewStyle(.circular)
                } else {
                    Image(systemName: "moon.fill")
                }
            }.containerBackground(for: .widget) { AccessoryWidgetBackground() }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: s.ramadan ? "moon.stars.fill" : (Prayer(rawValue: s.nextIndex)?.symbol ?? "moon.fill"))
                    Text(s.targetName).lineLimit(1)
                }.font(.caption.weight(.semibold))
                if let t = s.target { Text(t, style: .timer).font(.title3.weight(.bold)).monospacedDigit() }
                Text("\(nextTime) · \(s.city)").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }.containerBackground(for: .widget) { Color.clear }
        case .systemSmall:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Image(systemName: s.ramadan ? "moon.stars.fill" : (Prayer(rawValue: s.nextIndex)?.symbol ?? "moon.fill")).symbolRenderingMode(.hierarchical)
                    Text(s.city).lineLimit(1)
                }.font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
                Spacer(minLength: 0)
                Text(s.targetName).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
                if let t = s.target {
                    Text(t, style: .timer).font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(.white).minimumScaleFactor(0.6).lineLimit(1)
                }
                PrayerProgress(s: s).padding(.vertical, 3)
                Text(s.hijri.isEmpty ? nextTime : "\(s.hijri) · \(nextTime)").font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
            }
            .containerBackground(for: .widget) { skyGradient(s.phase, ramadan: s.ramadan) }
        case .systemMedium:
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.city).font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.9)).lineLimit(1)
                    Text(s.hijri.isEmpty ? s.hijriDate : s.hijri).font(.caption2).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                    Spacer(minLength: 0)
                    Text(s.targetName).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
                    if let t = s.target {
                        Text(t, style: .timer).font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(.white).minimumScaleFactor(0.6).lineLimit(1)
                    }
                    PrayerProgress(s: s).padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let d = s.day {
                    VStack(spacing: 1) {
                        ForEach(Prayer.allCases, id: \.rawValue) { p in
                            PrayerRow(p: p, time: d.times[p.rawValue], isNext: p.rawValue == s.nextIndex && !s.ramadan)
                        }
                    }
                    .frame(width: 138)
                }
            }
            .containerBackground(for: .widget) { skyGradient(s.phase, ramadan: s.ramadan) }
        default:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(s.city).font(.headline).foregroundStyle(.white)
                        Text(s.hijriDate).font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: s.ramadan ? "moon.stars.fill" : "building.columns.fill").font(.title3).foregroundStyle(.white.opacity(0.8))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.targetName).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
                    HStack(alignment: .firstTextBaseline) {
                        if let t = s.target { Text(t, style: .timer).font(.system(size: 40, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(.white) }
                        Spacer()
                        Text(nextTime).font(.title3.weight(.semibold)).monospacedDigit().foregroundStyle(.white.opacity(0.85))
                    }
                    PrayerProgress(s: s)
                    if !s.hijri.isEmpty { Text(s.hijri).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85)) }
                }
                .padding(12).background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                if let d = s.day {
                    VStack(spacing: 3) {
                        ForEach(Prayer.allCases, id: \.rawValue) { p in
                            PrayerRow(p: p, time: d.times[p.rawValue], isNext: p.rawValue == s.nextIndex && !s.ramadan, big: true)
                        }
                    }
                }
                Spacer(minLength: 0)
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
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

func wxGradient(_ code: Int, day: Bool) -> LinearGradient {
    func c(_ v: UInt) -> Color { Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255) }
    let p: (UInt, UInt)
    switch code {
    case 95...99: p = (0x23253A, 0x4A3F66)
    case 71...77, 85, 86: p = day ? (0x6F86A6, 0xAFC2D8) : (0x2A3550, 0x51607E)
    case 51...67, 80...82: p = day ? (0x3B4C66, 0x667A94) : (0x141C2E, 0x2F3D57)
    case 3, 45, 48: p = day ? (0x5A6A80, 0x8D9CB0) : (0x1A2133, 0x3A4459)
    default: p = day ? (0x2B74CF, 0x6BB2EE) : (0x0B1430, 0x2A3A6B)
    }
    return LinearGradient(colors: [c(p.0), c(p.1)], startPoint: .top, endPoint: .bottom)
}

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

struct WxIcon: View {
    let code: Int; let day: Bool; var size: CGFloat = 16
    var body: some View { Image(systemName: WX.symbol(code, day: day)).symbolRenderingMode(.multicolor).font(.system(size: size)).frame(height: size + 4) }
}

struct HourCell: View {
    let h: Weather.Hour
    var body: some View {
        VStack(spacing: 3) {
            Text(h.time).font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.8))
            WxIcon(code: h.code, day: h.isDay ?? true, size: 15)
            Text((h.pop ?? 0) >= 20 ? Fmt.pctShort(h.pop!) : " ").font(.system(size: 9.5, weight: .bold)).foregroundStyle(Color(red: 0.6, green: 0.85, blue: 1))
            Text("\(Int(h.temp.rounded()))°").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
        }.frame(maxWidth: .infinity)
    }
}

struct DayRow: View {
    let d: Weather.Day; let lo: Double; let hi: Double; let first: Bool
    var body: some View {
        HStack(spacing: 8) {
            Text(first ? T("Bugün") : Fmt.weekday(d.date)).font(.system(size: 14, weight: .semibold)).frame(width: 46, alignment: .leading)
            WxIcon(code: d.code, day: true, size: 15).frame(width: 24)
            Text(d.pop >= 20 ? Fmt.pctShort(d.pop) : "").font(.system(size: 10.5, weight: .bold)).foregroundStyle(Color(red: 0.6, green: 0.85, blue: 1)).frame(width: 32, alignment: .leading)
            Text("\(Int(d.min.rounded()))°").font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.7)).frame(width: 30, alignment: .trailing)
            GeometryReader { g in
                let span = max(hi - lo, 1), x0 = (d.min - lo) / span * g.size.width, x1 = (d.max - lo) / span * g.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.18))
                    Capsule().fill(LinearGradient(colors: [Color(red: 0.45, green: 0.8, blue: 1), Color(red: 1, green: 0.75, blue: 0.3)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(x1 - x0, 6)).offset(x: x0)
                }
            }.frame(height: 5)
            Text("\(Int(d.max.rounded()))°").font(.system(size: 14, weight: .semibold)).frame(width: 30, alignment: .trailing)
        }.foregroundStyle(.white)
    }
}

struct WeatherView: View {
    @Environment(\.widgetFamily) var family
    let e: WeatherEntry
    var summary: some View {
        let w = e.w
        return VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text(e.city).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                Image(systemName: "location.fill").font(.system(size: 9))
            }
            Text("\(Int(w.temp.rounded()))°").font(.system(size: family == .systemSmall ? 44 : 46, weight: .light)).minimumScaleFactor(0.7).lineLimit(1)
            Spacer(minLength: 0)
            WxIcon(code: w.code, day: w.isDay, size: 17)
            Text(WX.desc(w.code)).font(.system(size: 13, weight: .semibold)).lineLimit(1)
            Text("↑\(Int(w.max.rounded()))°  ↓\(Int(w.min.rounded()))°").font(.system(size: 13, weight: .medium)).opacity(0.85)
        }.foregroundStyle(.white)
    }
    var body: some View {
        let w = e.w
        Group {
            switch family {
            case .systemSmall:
                summary.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .systemMedium:
                HStack(alignment: .top, spacing: 8) {
                    summary.frame(width: 104, alignment: .leading)
                    VStack(spacing: 6) {
                        if let pop = w.pop, pop >= 30 {
                            HStack(spacing: 4) { Image(systemName: "umbrella.fill"); Text(String(format: T("Bugün yağış olasılığı %@"), Fmt.pctShort(pop))) }
                                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.9)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        } else if let f = w.feels {
                            Text(String(format: T("Hissedilen %d°"), Int(f.rounded()))).font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.9)).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Spacer(minLength: 0)
                        HStack(spacing: 0) { ForEach(Array(w.hours.prefix(5).enumerated()), id: \.offset) { _, h in HourCell(h: h) } }
                    }
                }
            default:
                VStack(spacing: 10) {
                    HStack(alignment: .top) {
                        summary
                        Spacer()
                        if let f = w.feels {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: T("Hissedilen %d°"), Int(f.rounded())))
                                if let pop = w.pop { Text(String(format: T("Yağış %@"), Fmt.pctShort(pop))) }
                            }.font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.85))
                        }
                    }.frame(height: 128)
                    HStack(spacing: 0) { ForEach(Array(w.hours.prefix(6).enumerated()), id: \.offset) { _, h in HourCell(h: h) } }
                        .padding(.vertical, 8).background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    let days = Array(w.days.prefix(5))
                    let lo = days.map(\.min).min() ?? 0, hi = days.map(\.max).max() ?? 1
                    VStack(spacing: 7) { ForEach(Array(days.enumerated()), id: \.offset) { i, d in DayRow(d: d, lo: lo, hi: hi, first: i == 0) } }
                    Spacer(minLength: 0)
                }
            }
        }
        .containerBackground(for: .widget) { wxGradient(w.code, day: w.isDay) }
    }
}

struct HavaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "hava", provider: WeatherProvider()) { e in
            WeatherView(e: e).widgetURL(URL(string: "rahimov://hava"))
        }
        .configurationDisplayName(T("Hava durumu"))
        .description(T("Şehrinin anlık hava durumu ve sonraki saatler."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
                    PrayerProgress(s: e.p)
                    Text(e.p.city).font(.caption2).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                }
                .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(skyGradient(e.p.phase, ramadan: e.p.ramadan), in: RoundedRectangle(cornerRadius: 14))
                // Hava
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: WX.symbol(e.w.code, day: e.w.isDay)).symbolRenderingMode(.multicolor)
                        Text("\(Int(e.w.temp.rounded()))°").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    }
                    Spacer(minLength: 0)
                    Text(WX.desc(e.w.code)).font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.9)).lineLimit(1)
                    Text("↑\(Int(e.w.max.rounded()))° ↓\(Int(e.w.min.rounded()))°").font(.caption2).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                }
                .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(wxGradient(e.w.code, day: e.w.isDay), in: RoundedRectangle(cornerRadius: 14))
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
