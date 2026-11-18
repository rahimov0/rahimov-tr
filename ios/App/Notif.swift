import Foundation
import UserNotifications

/// Namaz vakti bildirimleri: cihazda zamanlanır, sunucu gerekmez. iOS en fazla 64 bekleyen bildirime izin verir;
/// bu yüzden önümüzdeki günler için 60 bildirim kurulur ve uygulama açıldıkça yenilenir.
enum Notif {
    static var d: UserDefaults { AppGroup.defaults }

    static var enabled: Bool { get { d.bool(forKey: "notif.on") } set { d.set(newValue, forKey: "notif.on") } }
    static func isOn(_ p: Prayer) -> Bool { d.object(forKey: "notif.p\(p.rawValue)") as? Bool ?? (p != .gunes) }
    static func set(_ p: Prayer, _ v: Bool) { d.set(v, forKey: "notif.p\(p.rawValue)") }
    static var offset: Int { get { d.integer(forKey: "notif.offset") } set { d.set(newValue, forKey: "notif.offset") } }
    static var ramadan: Bool { get { d.object(forKey: "notif.ramadan") as? Bool ?? true } set { d.set(newValue, forKey: "notif.ramadan") } }
    static var sahurBefore: Int { get { d.object(forKey: "notif.sahur") as? Int ?? 45 } set { d.set(newValue, forKey: "notif.sahur") } }
    /// Bildirim sesi: "ezan" (kısa ezan, vakit girince), "zil" (yumuşak zil), "default" (iOS varsayılanı).
    static var sound: String { get { d.string(forKey: "notif.sound") ?? "ezan" } set { d.set(newValue, forKey: "notif.sound") } }

    /// Vakit girince ezan; önceden hatırlatma, güneş ve sahur için zil. iOS varsayılanı seçiliyse hep varsayılan.
    static func soundFor(adhan: Bool) -> UNNotificationSound {
        switch sound {
        case "default": return .default
        case "zil": return UNNotificationSound(named: UNNotificationSoundName("zil.caf"))
        default: return UNNotificationSound(named: UNNotificationSoundName(adhan ? "ezan.caf" : "zil.caf"))
        }
    }

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func reschedule() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard enabled else { return }
        let st = await center.notificationSettings()
        guard st.authorizationStatus == .authorized || st.authorizationStatus == .provisional else { return }
        let city = Store.city
        guard let days = try? await API.prayerDays(city, days: 12) else { return }
        let now = Date()
        var count = 0
        func add(_ id: String, _ title: String, _ body: String, _ at: Date, adhan: Bool = false) {
            guard at > now, count < 60 else { return }
            let c = UNMutableNotificationContent()
            c.title = title; c.body = body; c.sound = soundFor(adhan: adhan)
            c.threadIdentifier = "namaz"
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: at)
            center.add(UNNotificationRequest(identifier: id, content: c, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
            count += 1
        }
        for day in days {
            let isRamadan = ramadan && day.hijriMonth == 9
            let tag = Int(day.date.timeIntervalSince1970)
            if isRamadan {
                let imsak = day.times[Prayer.imsak.rawValue]
                add("sahur.\(tag)", T("Sahur vakti"), String(format: T("İmsaka %d dakika kaldı · %@"), sahurBefore, city.name), imsak.addingTimeInterval(Double(-sahurBefore * 60)))
            }
            for p in Prayer.allCases where isOn(p) {
                let t = day.times[p.rawValue]
                let at = t.addingTimeInterval(Double(-offset * 60))
                if isRamadan && p == .aksam {
                    add("iftar.\(tag)", T("İftar vakti"), String(format: T("Hayırlı iftarlar · %@ %@"), city.name, Fmt.time(t)), t, adhan: true)
                    continue
                }
                let title = offset > 0 ? String(format: T("%d dakika sonra %@"), offset, p.name) : String(format: T("%@ vakti"), p.name)
                add("p\(p.rawValue).\(tag)", title, "\(city.name) · \(Fmt.time(t))", at, adhan: offset == 0 && p != .gunes)
            }
            if count >= 60 { break }
        }
    }
}
