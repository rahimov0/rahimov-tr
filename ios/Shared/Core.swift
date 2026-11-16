import Foundation

// MARK: - Ortak ayarlar (uygulama + widget, App Group üzerinden)

enum AppGroup {
    static let id = "group.tr.rahimov.app"
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }
}

struct City: Codable, Equatable {
    var name: String
    var lat: Double
    var lon: Double
    static let istanbul = City(name: "İstanbul", lat: 41.0082, lon: 28.9784)
}

enum Store {
    static var city: City {
        get {
            if let d = AppGroup.defaults.data(forKey: "city"), let c = try? JSONDecoder().decode(City.self, from: d) { return c }
            return .istanbul
        }
        set { AppGroup.defaults.set(try? JSONEncoder().encode(newValue), forKey: "city") }
    }
    static var adsRemoved: Bool {
        get { AppGroup.defaults.bool(forKey: "adsRemoved") }
        set { AppGroup.defaults.set(newValue, forKey: "adsRemoved") }
    }
}

// MARK: - Dil

enum Lang: String { case tr, en, ru, az
    static var current: Lang {
        for id in Locale.preferredLanguages {
            if let l = Lang(rawValue: String(id.prefix(2)).lowercased()) { return l }
        }
        return .en
    }
    /// Sitedeki dil öneki
    var sitePrefix: String { self == .tr ? "" : "/" + rawValue }
    var locale: Locale { Locale(identifier: ["tr": "tr_TR", "en": "en_US", "ru": "ru_RU", "az": "az_AZ"][rawValue]!) }
}

/// Basit çeviri: anahtar Türkçe metindir.
func T(_ s: String) -> String {
    let l = Lang.current
    if l == .tr { return s }
    return Strings.table[s]?[l.rawValue] ?? s
}

// MARK: - Biçimlendirme

enum Fmt {
    static func num(_ v: Double, _ digits: Int = 2) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Lang.current == .az ? Locale(identifier: "tr_TR") : Lang.current.locale
        f.minimumFractionDigits = digits
        f.maximumFractionDigits = digits
        return f.string(from: NSNumber(value: v)) ?? String(v)
    }
    static func pct(_ v: Double) -> String {
        let s = num(abs(v), 2)
        return Lang.current == .tr ? "%" + s : s + "%"
    }
    static func pctShort(_ v: Int) -> String { Lang.current == .tr ? "%\(v)" : "\(v)%" }
    static func weekday(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Lang.current.locale; f.dateFormat = "EEE"; return f.string(from: d).capitalized(with: Lang.current.locale)
    }
    static func time(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Lang.current.locale; f.dateFormat = "HH:mm"; return f.string(from: d)
    }
}

// MARK: - Veri modelleri

struct Rate: Codable { var buy: Double; var sell: Double; var change: Double }

struct Market: Codable {
    var rates: [String: Rate]
    var updated: String
    static let placeholder = Market(rates: [
        "USD": Rate(buy: 50.37, sell: 50.38, change: 0.12), "EUR": Rate(buy: 55.5, sell: 55.6, change: -0.1),
        "GBP": Rate(buy: 66.5, sell: 66.6, change: 0.05), "GRA": Rate(buy: 6240, sell: 6250, change: 0.3),
        "CEYREKALTIN": Rate(buy: 10250, sell: 10330, change: 0.2)], updated: "")
}

struct Weather: Codable {
    var temp: Double; var code: Int; var isDay: Bool; var min: Double; var max: Double
    var hours: [Hour]
    var days: [Day] = []
    var feels: Double? = nil
    var pop: Int? = nil          // bugünkü en yüksek yağış olasılığı
    struct Hour: Codable { var time: String; var temp: Double; var code: Int; var pop: Int? = nil; var isDay: Bool? = nil }
    struct Day: Codable { var date: Date; var code: Int; var min: Double; var max: Double; var pop: Int }
    static let placeholder: Weather = {
        let h = (1...6).map { i in Hour(time: String(format: "%02d:00", (Calendar.current.component(.hour, from: Date()) + i) % 24), temp: 14 + Double(i % 3), code: [2, 2, 3, 61, 3, 2][i - 1], pop: [0, 10, 30, 60, 40, 10][i - 1], isDay: true) }
        let d = (0..<6).map { i in Day(date: Calendar.current.date(byAdding: .day, value: i, to: Calendar.current.startOfDay(for: Date()))!, code: [2, 61, 3, 1, 0, 63][i], min: 9 + Double(i), max: 16 + Double(i), pop: [10, 80, 30, 0, 0, 70][i]) }
        return Weather(temp: 14, code: 2, isDay: true, min: 9, max: 16, hours: h, days: d, feels: 12, pop: 10)
    }()
}

struct PrayerDay: Codable {
    var date: Date               // günün başlangıcı
    var times: [Date]            // 6 vakit: imsak, güneş, öğle, ikindi, akşam, yatsı
    var hijriMonth: Int
    var hijriDay: Int
    var hijriYear: String
}

enum Prayer: Int, CaseIterable { case imsak, gunes, ogle, ikindi, aksam, yatsi
    var key: String { ["Imsak", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"][rawValue] }
    var name: String { T(["İmsak", "Güneş", "Öğle", "İkindi", "Akşam", "Yatsı"][rawValue]) }
}

// MARK: - Ağ

enum API {
    static func get(_ url: String) async throws -> Data {
        var req = URLRequest(url: URL(string: url)!)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 15
        let (d, r) = try await URLSession.shared.data(for: req)
        if let h = r as? HTTPURLResponse, h.statusCode >= 400 { throw URLError(.badServerResponse) }
        return d
    }

    static func market() async throws -> Market {
        let stamp = Int(Date().timeIntervalSince1970 / 60)
        let d = try await get("https://finans.truncgil.com/v4/today.json?_=\(stamp)")
        guard let j = try JSONSerialization.jsonObject(with: d) as? [String: Any] else { throw URLError(.cannotParseResponse) }
        var rates: [String: Rate] = [:]
        for (k, v) in j {
            guard let o = v as? [String: Any], let s = (o["Selling"] as? NSNumber)?.doubleValue, s > 0 else { continue }
            rates[k] = Rate(buy: (o["Buying"] as? NSNumber)?.doubleValue ?? s, sell: s, change: (o["Change"] as? NSNumber)?.doubleValue ?? 0)
        }
        let m = Market(rates: rates, updated: j["Update_Date"] as? String ?? "")
        AppGroup.defaults.set(try? JSONEncoder().encode(m), forKey: "cache.market")
        return m
    }
    static var cachedMarket: Market? {
        guard let d = AppGroup.defaults.data(forKey: "cache.market") else { return nil }
        return try? JSONDecoder().decode(Market.self, from: d)
    }

    static func weather(_ c: City) async throws -> Weather {
        let u = "https://api.open-meteo.com/v1/forecast?latitude=\(c.lat)&longitude=\(c.lon)&current=temperature_2m,apparent_temperature,weather_code,is_day&hourly=temperature_2m,weather_code,precipitation_probability,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto&forecast_days=7"
        let d = try await get(u)
        guard let j = try JSONSerialization.jsonObject(with: d) as? [String: Any],
              let cur = j["current"] as? [String: Any], let daily = j["daily"] as? [String: Any],
              let hourly = j["hourly"] as? [String: Any] else { throw URLError(.cannotParseResponse) }
        func nums(_ o: [String: Any], _ k: String) -> [Double] { (o[k] as? [Any] ?? []).map { ($0 as? NSNumber)?.doubleValue ?? 0 } }
        let times = hourly["time"] as? [String] ?? []
        let temps = nums(hourly, "temperature_2m"), codes = nums(hourly, "weather_code"), pops = nums(hourly, "precipitation_probability"), days = nums(hourly, "is_day")
        let now = String((cur["time"] as? String ?? "").prefix(13))
        let start = times.firstIndex { $0.prefix(13) >= now } ?? 0
        var hours: [Weather.Hour] = []
        var i = start + 1
        while i < min(start + 7, times.count, temps.count, codes.count) {
            hours.append(.init(time: String(times[i].suffix(5)), temp: temps[i], code: Int(codes[i]),
                               pop: i < pops.count ? Int(pops[i]) : nil, isDay: i < days.count ? days[i] == 1 : nil)); i += 1
        }
        let dates = daily["time"] as? [String] ?? []
        let dmax = nums(daily, "temperature_2m_max"), dmin = nums(daily, "temperature_2m_min"), dcode = nums(daily, "weather_code"), dpop = nums(daily, "precipitation_probability_max")
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        var dayList: [Weather.Day] = []
        for k in 0..<min(dates.count, dmax.count, dmin.count, dcode.count) {
            guard let dt = f.date(from: dates[k]) else { continue }
            dayList.append(.init(date: dt, code: Int(dcode[k]), min: dmin[k], max: dmax[k], pop: k < dpop.count ? Int(dpop[k]) : 0))
        }
        let w = Weather(temp: (cur["temperature_2m"] as? NSNumber)?.doubleValue ?? 0,
                        code: (cur["weather_code"] as? NSNumber)?.intValue ?? 0,
                        isDay: ((cur["is_day"] as? NSNumber)?.intValue ?? 1) == 1,
                        min: dmin.first ?? 0, max: dmax.first ?? 0, hours: hours, days: dayList,
                        feels: (cur["apparent_temperature"] as? NSNumber)?.doubleValue,
                        pop: dpop.first.map { Int($0) })
        AppGroup.defaults.set(try? JSONEncoder().encode(w), forKey: "cache.weather2")
        return w
    }
    static var cachedWeather: Weather? {
        guard let d = AppGroup.defaults.data(forKey: "cache.weather2") else { return nil }
        return try? JSONDecoder().decode(Weather.self, from: d)
    }

    /// Bir ayın namaz vakitleri (Diyanet yöntemi). Saatler cihazın saat dilimine göre Date olarak döner.
    static func prayerMonth(_ c: City, year: Int, month: Int) async throws -> [PrayerDay] {
        let key = "cache.pray.\(Int(c.lat * 100)).\(Int(c.lon * 100)).\(year).\(month)"
        if let d = AppGroup.defaults.data(forKey: key), let v = try? JSONDecoder().decode([PrayerDay].self, from: d), !v.isEmpty { return v }
        let d = try await get("https://api.aladhan.com/v1/calendar/\(year)/\(month)?latitude=\(c.lat)&longitude=\(c.lon)&method=13")
        guard let j = try JSONSerialization.jsonObject(with: d) as? [String: Any], let arr = j["data"] as? [[String: Any]] else { throw URLError(.cannotParseResponse) }
        var out: [PrayerDay] = []
        var cal = Calendar(identifier: .gregorian)
        for day in arr {
            guard let timings = day["timings"] as? [String: String], let date = day["date"] as? [String: Any],
                  let greg = date["gregorian"] as? [String: Any], let ds = greg["date"] as? String,
                  let meta = day["meta"] as? [String: Any], let tzName = meta["timezone"] as? String,
                  let tz = TimeZone(identifier: tzName) else { continue }
            cal.timeZone = tz
            let p = ds.split(separator: "-").compactMap { Int($0) }   // dd-mm-yyyy
            guard p.count == 3, let base = cal.date(from: DateComponents(year: p[2], month: p[1], day: p[0])) else { continue }
            var times: [Date] = []
            for pr in Prayer.allCases {
                let s = String((timings[pr.key] ?? "00:00").prefix(5)).split(separator: ":").compactMap { Int($0) }
                times.append(cal.date(bySettingHour: s.first ?? 0, minute: s.count > 1 ? s[1] : 0, second: 0, of: base) ?? base)
            }
            let h = date["hijri"] as? [String: Any]
            let hm = ((h?["month"] as? [String: Any])?["number"] as? NSNumber)?.intValue ?? 0
            let hd = Int(h?["day"] as? String ?? "0") ?? 0
            out.append(PrayerDay(date: base, times: times, hijriMonth: hm, hijriDay: hd, hijriYear: h?["year"] as? String ?? ""))
        }
        if !out.isEmpty { AppGroup.defaults.set(try? JSONEncoder().encode(out), forKey: key) }
        return out
    }

    /// Bugünden başlayarak `days` günlük vakitler (gerekirse iki ay birleştirilir).
    static func prayerDays(_ c: City, from start: Date = Date(), days: Int) async throws -> [PrayerDay] {
        let cal = Calendar(identifier: .gregorian)
        let y = cal.component(.year, from: start), m = cal.component(.month, from: start)
        var all = try await prayerMonth(c, year: y, month: m)
        let nm = m == 12 ? 1 : m + 1, ny = m == 12 ? y + 1 : y
        if let next = try? await prayerMonth(c, year: ny, month: nm) { all += next }
        let today = cal.startOfDay(for: start)
        return Array(all.filter { cal.startOfDay(for: $0.date) >= today }.prefix(days))
    }
}

// MARK: - Hicri aylar

enum Hijri {
    static func month(_ n: Int) -> String {
        let tr = ["Muharrem", "Safer", "Rebiülevvel", "Rebiülahir", "Cemaziyelevvel", "Cemaziyelahir", "Recep", "Şaban", "Ramazan", "Şevval", "Zilkade", "Zilhicce"]
        let en = ["Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani", "Jumada al-Ula", "Jumada al-Akhirah", "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhu al-Qadah", "Dhu al-Hijjah"]
        let ru = ["Мухаррам", "Сафар", "Раби аль-авваль", "Раби ас-сани", "Джумада аль-уля", "Джумада ас-сания", "Раджаб", "Шаабан", "Рамадан", "Шавваль", "Зуль-када", "Зуль-хиджа"]
        let az = ["Məhərrəm", "Səfər", "Rəbiüləvvəl", "Rəbiülaxır", "Cəmadiyələvvəl", "Cəmadiyəlaxır", "Rəcəb", "Şaban", "Ramazan", "Şəvval", "Zilqədə", "Zilhiccə"]
        guard (1...12).contains(n) else { return "" }
        switch Lang.current { case .tr: return tr[n - 1]; case .en: return en[n - 1]; case .ru: return ru[n - 1]; case .az: return az[n - 1] }
    }
    static func date(_ d: PrayerDay) -> String { d.hijriMonth > 0 ? "\(d.hijriDay) \(month(d.hijriMonth)) \(d.hijriYear)" : "" }
}

// MARK: - Hava durumu kodları

enum WX {
    static func desc(_ code: Int) -> String {
        switch code {
        case 0: return T("Açık")
        case 1: return T("Az bulutlu")
        case 2: return T("Parçalı bulutlu")
        case 3: return T("Kapalı")
        case 45, 48: return T("Sisli")
        case 51...57: return T("Çisenti")
        case 61, 63, 80, 81: return T("Yağmur")
        case 65, 82: return T("Kuvvetli yağmur")
        case 66, 67: return T("Dondurucu yağmur")
        case 71...77, 85, 86: return T("Kar")
        case 95...99: return T("Gök gürültülü fırtına")
        default: return "—"
        }
    }
    static func symbol(_ code: Int, day: Bool = true) -> String {
        switch code {
        case 0: return day ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: return day ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}
