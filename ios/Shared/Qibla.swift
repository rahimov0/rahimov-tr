import Foundation
import AppIntents

/// Kıble hesabı: büyük daire üzerinde Kâbe'ye başlangıç açısı (kuzeyden saat yönünde).
enum Qibla {
    static let kaabaLat = 21.422487, kaabaLon = 39.826206

    static func bearing(lat: Double, lon: Double) -> Double {
        let φ1 = lat * .pi / 180, φ2 = kaabaLat * .pi / 180, Δλ = (kaabaLon - lon) * .pi / 180
        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
        let b = atan2(y, x) * 180 / .pi
        return (b + 360).truncatingRemainder(dividingBy: 360)
    }

    static func distanceKm(lat: Double, lon: Double) -> Double {
        City(name: "", lat: lat, lon: lon).distance(to: City(name: "", lat: kaabaLat, lon: kaabaLon)) / 1000
    }

    static func direction(_ deg: Double) -> String {
        let names = ["Kuzey", "Kuzeydoğu", "Doğu", "Güneydoğu", "Güney", "Güneybatı", "Batı", "Kuzeybatı"]
        return T(names[Int((deg + 22.5) / 45) % 8])
    }

    /// Denetim Merkezi düğmesi ya da widget'tan "Kıble'yi aç" isteği (uygulama açılınca okunur)
    static var pendingOpen: Bool {
        get { AppGroup.defaults.bool(forKey: "qibla.open") }
        set { AppGroup.defaults.set(newValue, forKey: "qibla.open") }
    }
}

/// Uygulamayı açıp kıble pusulasını gösterir (Denetim Merkezi / Kısayollar).
struct OpenQiblaIntent: AppIntent {
    static var title: LocalizedStringResource = "Kıble pusulası"
    static var description = IntentDescription("KROV'da kıble pusulasını açar.")
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        Qibla.pendingOpen = true
        return .result()
    }
}
