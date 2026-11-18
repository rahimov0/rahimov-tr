import Foundation
import CoreLocation

/// Konumdan şehir/ilçe adı (Türkiye'de ilçe adı: Şişli, Fatih…)
enum Geo {
    static func city(from l: CLLocation) async -> City {
        let pm = try? await CLGeocoder().reverseGeocodeLocation(l, preferredLocale: Lang.current.locale).first
        let name = pm?.subAdministrativeArea ?? pm?.locality ?? pm?.administrativeArea ?? T("Konumun")
        return City(name: name, lat: (l.coordinate.latitude * 1000).rounded() / 1000, lon: (l.coordinate.longitude * 1000).rounded() / 1000)
    }
}

/// Tek seferlik konum isteği (uygulama ve widget'lar için), zaman aşımıyla
final class OneShotLocation: NSObject, CLLocationManagerDelegate {
    private let m = CLLocationManager()
    private var cont: CheckedContinuation<CLLocation?, Never>?
    override init() { super.init(); m.delegate = self; m.desiredAccuracy = kCLLocationAccuracyHundredMeters }

    var authorized: Bool { [.authorizedWhenInUse, .authorizedAlways].contains(m.authorizationStatus) }
    var authorizedForWidgets: Bool { authorized && m.isAuthorizedForWidgetUpdates }

    @MainActor func get(timeout: Double = 8) async -> CLLocation? {
        await withCheckedContinuation { (c: CheckedContinuation<CLLocation?, Never>) in
            cont = c
            m.requestLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in self?.finish(self?.m.location) }
        }
    }
    private func finish(_ l: CLLocation?) { let c = cont; cont = nil; c?.resume(returning: l) }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { finish(locations.last) }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { finish(manager.location) }
}
