import SwiftUI
import CoreLocation
import WidgetKit

/// Uygulama açıldıkça bulunduğun yeri kontrol eder; yer değiştirdiysen hava, namaz, widget ve bildirimler yeni yere geçer.
/// Kullanıcı elle şehir seçerse otomatik mod kapanır; "Konumumu kullan" ile yeniden açılır.
@MainActor final class AutoLocation: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = AutoLocation()
    @Published var busy = false
    @Published var error: String?
    @Published var auto = Store.autoLocation
    @Published var city = Store.city
    private let m = CLLocationManager()
    private var waiting = false

    override init() { super.init(); m.delegate = self; m.desiredAccuracy = kCLLocationAccuracyHundredMeters }

    /// Uygulama öne gelince çağrılır
    func refresh(force: Bool = false) {
        guard Store.autoLocation || force else { return }
        error = nil
        switch m.authorizationStatus {
        case .notDetermined: waiting = true; busy = true; m.requestWhenInUseAuthorization()
        case .denied, .restricted:
            busy = false
            if force { error = T("Konum izni kapalı. Ayarlar > KROV > Konum'dan açabilirsin.") }
        default: waiting = true; busy = true; m.requestLocation()
        }
    }

    func useAuto() { Store.autoLocation = true; auto = true; refresh(force: true) }

    func setManual(_ c: City) {
        Store.autoLocation = false; auto = false
        apply(c, force: true)
    }

    func apply(_ c: City, force: Bool = false) {
        let old = Store.city
        let changed = force || old.name != c.name || old.distance(to: c) > 800
        Store.city = c; city = c
        guard changed else { return }
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .cityChanged, object: nil)
        Task { await Notif.reschedule() }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let s = manager.authorizationStatus
            if waiting && (s == .authorizedWhenInUse || s == .authorizedAlways) { manager.requestLocation() }
            else if waiting && (s == .denied || s == .restricted) { waiting = false; busy = false; error = T("Konum izni verilmedi.") }
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        Task { @MainActor in
            guard waiting else { return }
            waiting = false
            let c = await Geo.city(from: l)
            busy = false
            if Store.autoLocation { apply(c) }
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in if waiting { waiting = false; busy = false; self.error = T("Konum alınamadı.") } }
    }
}

/// Sitedeki şehir düğmesine dokununca açılan pencere
struct CityPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var loc = AutoLocation.shared
    var body: some View {
        NavigationStack {
            CitySearch(onPick: { c in loc.setManual(c); dismiss() }, onAuto: { loc.useAuto(); dismiss() })
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(T("Kapat")) { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
