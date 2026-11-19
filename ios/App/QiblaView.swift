import SwiftUI
import CoreLocation
import UIKit

/// Pusula: konum + yön sensörü
@MainActor final class QiblaCompass: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double?          // telefonun baktığı yön (gerçek kuzeye göre)
    @Published var accuracy: Double = -1
    @Published var location: CLLocation?
    @Published var denied = false
    private let lm = CLLocationManager()

    override init() {
        super.init()
        lm.delegate = self
        lm.headingFilter = 1
        lm.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    func start() {
        if lm.authorizationStatus == .notDetermined { lm.requestWhenInUseAuthorization() }
        lm.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { lm.startUpdatingHeading() }
    }
    func stop() { lm.stopUpdatingHeading(); lm.stopUpdatingLocation() }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateHeading h: CLHeading) {
        let v = h.trueHeading >= 0 ? h.trueHeading : h.magneticHeading
        let acc = h.headingAccuracy
        Task { @MainActor in self.heading = v; self.accuracy = acc }
    }
    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations l: [CLLocation]) {
        guard let last = l.last else { return }
        Task { @MainActor in self.location = last }
    }
    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        let s = m.authorizationStatus
        Task { @MainActor in
            self.denied = s == .denied || s == .restricted
            if s == .authorizedWhenInUse || s == .authorizedAlways { self.start() }
        }
    }
}

struct QiblaView: View {
    @StateObject private var c = QiblaCompass()
    @Environment(\.dismiss) private var dismiss
    @State private var wasAligned = false

    private var lat: Double { c.location?.coordinate.latitude ?? Store.city.lat }
    private var lon: Double { c.location?.coordinate.longitude ?? Store.city.lon }
    private var qibla: Double { Qibla.bearing(lat: lat, lon: lon) }
    /// Kıbleye göre sapma: -180…180
    private var delta: Double? {
        guard let h = c.heading else { return nil }
        var d = (qibla - h).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }; if d < -180 { d += 360 }
        return d
    }
    private var aligned: Bool { (delta.map { abs($0) < 4 }) ?? false }
    private let green = Color(red: 0.18, green: 0.75, blue: 0.45)
    private let gold = Color(red: 0.95, green: 0.75, blue: 0.3)

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: aligned ? [Color(red: 0.03, green: 0.2, blue: 0.13), Color(red: 0.05, green: 0.33, blue: 0.2)] : [Color(red: 0.05, green: 0.07, blue: 0.15), Color(red: 0.12, green: 0.15, blue: 0.3)],
                               startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.35), value: aligned)
                VStack(spacing: 22) {
                    VStack(spacing: 6) {
                        Text(aligned ? T("Kıbleye dönüksün") : (delta.map { $0 > 0 ? T("Sağa dön") : T("Sola dön") } ?? T("Pusula hazırlanıyor…")))
                            .font(.title2.weight(.bold)).foregroundStyle(aligned ? green : .white)
                        if let d = delta, !aligned { Text("\(Int(abs(d).rounded()))°").font(.headline).foregroundStyle(.white.opacity(0.7)).monospacedDigit() }
                    }
                    .frame(height: 64)
                    dial.frame(width: 300, height: 300)
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            info(T("Kıble açısı"), "\(Int(qibla.rounded()))° · \(Qibla.direction(qibla))")
                            info(T("Kâbe'ye uzaklık"), Fmt.num(Qibla.distanceKm(lat: lat, lon: lon), 0) + " km")
                        }
                        if c.accuracy < 0 || c.accuracy > 20 {
                            Label(T("Daha doğru sonuç için telefonu havada 8 çizer gibi hareket ettir; metal ve mıknatıslardan uzak tut."), systemImage: "infinity")
                                .font(.footnote).foregroundStyle(.white.opacity(0.75)).multilineTextAlignment(.center).padding(.horizontal)
                        }
                        if c.denied {
                            Text(T("Konum izni kapalı; seçili şehre göre hesaplanıyor. Ayarlar > KROV > Konum'dan açabilirsin."))
                                .font(.footnote).foregroundStyle(.orange).multilineTextAlignment(.center).padding(.horizontal)
                        }
                        if c.heading == nil && !CLLocationManager.headingAvailable() {
                            Text(T("Bu cihazda pusula yok.")).font(.footnote).foregroundStyle(.orange)
                        }
                    }
                }
                .padding()
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Kapat")) { dismiss() }.tint(.white) } }
            .navigationTitle(T("Kıble")).navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { c.start(); UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { c.stop(); UIApplication.shared.isIdleTimerDisabled = false }
        .onChange(of: aligned) { _, a in
            if a && !wasAligned { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            wasAligned = a
        }
    }

    private func info(_ t: String, _ v: String) -> some View {
        VStack(spacing: 2) {
            Text(t).font(.caption).foregroundStyle(.white.opacity(0.6))
            Text(v).font(.subheadline.weight(.bold)).foregroundStyle(.white).monospacedDigit()
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Kadran telefonla birlikte döner; üstteki sabit işaret telefonun baktığı yön, Kâbe simgesi kıble.
    private var dial: some View {
        let rot = -(c.heading ?? 0)
        return ZStack {
            Circle().fill(.white.opacity(0.05))
            Circle().stroke(aligned ? green : .white.opacity(0.25), lineWidth: aligned ? 4 : 2)
            ZStack {
                ForEach(0..<72, id: \.self) { i in
                    Rectangle().fill(.white.opacity(i % 6 == 0 ? 0.7 : 0.25))
                        .frame(width: i % 6 == 0 ? 2 : 1, height: i % 6 == 0 ? 14 : 7)
                        .offset(y: -138).rotationEffect(.degrees(Double(i) * 5))
                }
                ForEach(Array(["K", "D", "G", "B"].enumerated()), id: \.offset) { i, s in
                    Text(T(s)).font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(i == 0 ? Color(red: 1, green: 0.42, blue: 0.35) : .white.opacity(0.85))
                        .rotationEffect(.degrees(-Double(i) * 90 - rot))
                        .offset(y: -108).rotationEffect(.degrees(Double(i) * 90))
                }
                // Kıble ışını ve Kâbe
                Capsule().fill(LinearGradient(colors: [gold, gold.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 6, height: 96).offset(y: -52).rotationEffect(.degrees(qibla))
                KaabaIcon().frame(width: 34, height: 34)
                    .rotationEffect(.degrees(-qibla - rot))
                    .offset(y: -112).rotationEffect(.degrees(qibla))
            }
            .rotationEffect(.degrees(rot))
            .animation(.interpolatingSpring(stiffness: 60, damping: 14), value: rot)
            // Telefonun baktığı yön
            Triangle().fill(aligned ? green : .white).frame(width: 18, height: 14).offset(y: -160)
            Circle().fill(aligned ? green : gold).frame(width: 14, height: 14)
        }
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path { Path { p in p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath() } }
}

/// Basit Kâbe simgesi: siyah küp ve altın kuşak
struct KaabaIcon: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: w * 0.08).fill(Color(white: 0.08))
                    .overlay(RoundedRectangle(cornerRadius: w * 0.08).stroke(.white.opacity(0.35), lineWidth: 1))
                Rectangle().fill(Color(red: 0.95, green: 0.75, blue: 0.3)).frame(height: w * 0.12).offset(y: w * 0.22)
            }
        }
    }
}
