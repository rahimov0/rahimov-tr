import SwiftUI
import CoreLocation
import WidgetKit
import UIKit

struct SettingsView: View {
    @Binding var path: [String]
    @StateObject private var loc = LocationFetcher()
    @State private var city = Store.city
    @State private var notifOn = Notif.enabled
    @State private var prayers: [Bool] = Prayer.allCases.map { Notif.isOn($0) }
    @State private var offset = Notif.offset
    @State private var ramadan = Notif.ramadan
    @State private var sahur = Notif.sahurBefore
    @State private var denied = false

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section(T("Araçlar")) {
                    NavigationLink(value: "deprem") { Label(T("Son depremler"), systemImage: "waveform.path.ecg") }
                    NavigationLink(value: "tatil") { Label(T("Resmî tatiller"), systemImage: "calendar") }
                }
                Section(T("Konum")) {
                    LabeledContent(T("Şehir"), value: city.name)
                    Button { loc.request() } label: { Label(loc.busy ? T("Konum alınıyor…") : T("Konumumu kullan"), systemImage: "location.fill") }
                        .disabled(loc.busy)
                    NavigationLink { CitySearch { c in setCity(c) } } label: { Label(T("Şehir ara"), systemImage: "magnifyingglass") }
                    if let e = loc.error { Text(e).font(.footnote).foregroundStyle(.secondary) }
                }
                .onChange(of: loc.found) { _, c in if let c { setCity(c) } }

                Section {
                    Toggle(T("Namaz vakti bildirimleri"), isOn: $notifOn)
                        .onChange(of: notifOn) { _, v in
                            Task {
                                if v { let ok = await Notif.requestPermission(); if !ok { denied = true; notifOn = false; return } }
                                Notif.enabled = notifOn; await Notif.reschedule()
                            }
                        }
                    if notifOn {
                        ForEach(Prayer.allCases, id: \.rawValue) { p in
                            Toggle(p.name, isOn: Binding(get: { prayers[p.rawValue] }, set: { prayers[p.rawValue] = $0; Notif.set(p, $0); Task { await Notif.reschedule() } }))
                        }
                        Picker(T("Ne zaman"), selection: $offset) {
                            Text(T("Vakit girince")).tag(0)
                            ForEach([5, 10, 15, 30, 45], id: \.self) { m in Text(String(format: T("%d dk önce"), m)).tag(m) }
                        }
                        .onChange(of: offset) { _, v in Notif.offset = v; Task { await Notif.reschedule() } }
                        Toggle(T("Ramazan'da sahur ve iftar hatırlatması"), isOn: $ramadan)
                            .onChange(of: ramadan) { _, v in Notif.ramadan = v; Task { await Notif.reschedule() } }
                        if ramadan {
                            Picker(T("Sahur hatırlatması"), selection: $sahur) {
                                ForEach([30, 45, 60, 90], id: \.self) { m in Text(String(format: T("İmsaktan %d dk önce"), m)).tag(m) }
                            }
                            .onChange(of: sahur) { _, v in Notif.sahurBefore = v; Task { await Notif.reschedule() } }
                        }
                    }
                } header: { Text(T("Bildirimler")) } footer: {
                    Text(denied ? T("Bildirim izni kapalı. Ayarlar > KROV > Bildirimler'den açabilirsin.") : T("Vakitler Diyanet yöntemiyle, seçtiğin şehre göre hesaplanır."))
                }

                Section(T("Widget'lar")) {
                    Text(T("Ana ekranda boş bir yere basılı tut, sol üstteki + düğmesine dokun ve “KROV”u ara. Panel, Namaz, Döviz ve Hava widget'larından istediğini ekleyebilirsin. Namaz widget'ı kilit ekranına da eklenebilir."))
                        .font(.callout).foregroundStyle(.secondary)
                }

                Section {
                    ForEach(Sources.all, id: \.name) { src in
                        Link(destination: URL(string: src.url)!) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(src.name).foregroundStyle(.primary)
                                Text(T(src.what)).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: { Text(T("Veri kaynakları")) } footer: { Text(T("Veriler bilgilendirme amaçlıdır; yatırım tavsiyesi değildir. Lisanslar ve ayrıntılar için kaynağa dokun.")) }

                Section(T("Hakkında")) {
                    Link(destination: URL(string: "https://rahimov.tr" + Lang.current.sitePrefix + "/gizlilik/")!) { Label(T("Gizlilik Politikası"), systemImage: "hand.raised.fill") }
                    Link(destination: URL(string: "https://rahimov.tr" + Lang.current.sitePrefix + "/iletisim/")!) { Label(T("İletişim"), systemImage: "envelope.fill") }
                    LabeledContent(T("Sürüm"), value: (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "")
                }
            }
            .navigationTitle(T("Daha fazla"))
            .navigationDestination(for: String.self) { d in
                Group {
                    if d == "deprem" { WebTab(id: "daha:deprem", path: "/deprem/").navigationTitle(T("Son depremler")) }
                    else { WebTab(id: "daha:tatil", path: "/resmi-tatiller/").navigationTitle(T("Resmî tatiller")) }
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .onReceive(NotificationCenter.default.publisher(for: .cityChanged)) { _ in city = Store.city }
        }
    }

    private func setCity(_ c: City) {
        city = c
        Store.city = c
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .cityChanged, object: nil)
        Task { await Notif.reschedule() }
    }
}

// MARK: - Konum

@MainActor final class LocationFetcher: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var found: City?
    @Published var busy = false
    @Published var error: String?
    var onFound: ((City) -> Void)?
    private let m = CLLocationManager()
    override init() { super.init(); m.delegate = self; m.desiredAccuracy = kCLLocationAccuracyKilometer }

    func request() {
        error = nil; busy = true
        switch m.authorizationStatus {
        case .notDetermined: m.requestWhenInUseAuthorization()
        case .denied, .restricted: busy = false; error = T("Konum izni kapalı. Ayarlar > KROV > Konum'dan açabilirsin.")
        default: m.requestLocation()
        }
    }
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let s = manager.authorizationStatus
            if busy && (s == .authorizedWhenInUse || s == .authorizedAlways) { manager.requestLocation() }
            else if busy && (s == .denied || s == .restricted) { busy = false; error = T("Konum izni verilmedi.") }
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        Task { @MainActor in
            let pm = try? await CLGeocoder().reverseGeocodeLocation(l, preferredLocale: Lang.current.locale).first
            let name = pm?.locality ?? pm?.administrativeArea ?? T("Konumun")
            let c = City(name: name, lat: (l.coordinate.latitude * 1000).rounded() / 1000, lon: (l.coordinate.longitude * 1000).rounded() / 1000)
            found = c
            onFound?(c)
            busy = false
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in busy = false; self.error = T("Konum alınamadı.") }
    }
}

// MARK: - Şehir arama (Open-Meteo)

struct CitySearch: View {
    var onPick: (City) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var q = ""
    @State private var results: [Hit] = []
    struct Hit: Identifiable { let id = UUID(); let city: City; let sub: String }

    var body: some View {
        List(results) { item in
            Button { onPick(item.city); dismiss() } label: {
                VStack(alignment: .leading) { Text(item.city.name).foregroundStyle(.primary); Text(item.sub).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .searchable(text: $q, prompt: T("Şehir ya da ilçe"))
        .task(id: q) {
            guard q.count >= 2 else { results = []; return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            let u = "https://geocoding-api.open-meteo.com/v1/search?name=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&count=10&language=\(Lang.current.rawValue)"
            guard let d = try? await API.get(u), let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any], let r = j["results"] as? [[String: Any]] else { results = []; return }
            results = r.compactMap { o in
                guard let n = o["name"] as? String, let la = (o["latitude"] as? NSNumber)?.doubleValue, let lo = (o["longitude"] as? NSNumber)?.doubleValue else { return nil }
                let sub = [o["admin1"] as? String, o["country"] as? String].compactMap { $0 }.joined(separator: ", ")
                return Hit(city: City(name: n, lat: la, lon: lo), sub: sub)
            }
        }
        .navigationTitle(T("Şehir ara"))
    }
}

// MARK: - Veri kaynakları (kaynak gösterimi)

enum Sources {
    struct S { let name: String; let what: String; let url: String }
    static let all: [S] = [
        S(name: "Truncgil Finans", what: "Döviz ve altın fiyatları", url: "https://finans.truncgil.com/"),
        S(name: "Frankfurter (ECB)", what: "Döviz kuru grafikleri", url: "https://frankfurter.dev/"),
        S(name: "Exchange API (fawazahmed0)", what: "Diğer para birimlerinin grafikleri", url: "https://github.com/fawazahmed0/exchange-api"),
        S(name: "Open-Meteo", what: "Hava durumu ve şehir arama (CC BY 4.0)", url: "https://open-meteo.com/"),
        S(name: "AlAdhan", what: "Namaz vakitleri (Diyanet yöntemi)", url: "https://aladhan.com/"),
        S(name: "Kandilli Rasathanesi (KOERI)", what: "Son depremler", url: "http://www.koeri.boun.edu.tr/scripts/lst0.asp"),
        S(name: "CoinGecko", what: "Kripto para fiyatları", url: "https://www.coingecko.com/"),
        S(name: "Nager.Date", what: "Resmî tatiller", url: "https://date.nager.at/"),
        S(name: "BigDataCloud", what: "Konumdan şehir adı", url: "https://www.bigdatacloud.com/"),
    ]
}
