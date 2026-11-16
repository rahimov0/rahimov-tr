import SwiftUI

// Namaz widget'larının arka planı: vakte göre gökyüzü, güneş/ay, yıldızlar ve cami silueti.
// phase: 0 imsak–güneş (tan), 1 sabah, 2 öğle, 3 ikindi, 4 akşam (gün batımı), 5 yatsı (gece)

private func hex(_ v: UInt) -> Color {
    Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
}

struct MosqueShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        func x(_ v: CGFloat) -> CGFloat { r.minX + v * r.width }
        func y(_ v: CGFloat) -> CGFloat { r.minY + v * r.height }
        // Zemin
        p.addRect(CGRect(x: x(0), y: y(0.93), width: r.width, height: r.height * 0.07))
        // Ana gövde ve kanatlar
        p.addRect(CGRect(x: x(0.30), y: y(0.62), width: r.width * 0.40, height: r.height * 0.31))
        p.addRect(CGRect(x: x(0.22), y: y(0.74), width: r.width * 0.56, height: r.height * 0.19))
        // Ana kubbe
        p.addEllipse(in: CGRect(x: x(0.33), y: y(0.40), width: r.width * 0.34, height: r.height * 0.44))
        p.addRect(CGRect(x: x(0.33), y: y(0.60), width: r.width * 0.34, height: r.height * 0.04))
        // Alem
        p.addRect(CGRect(x: x(0.497), y: y(0.30), width: r.width * 0.006, height: r.height * 0.11))
        p.addEllipse(in: CGRect(x: x(0.491), y: y(0.335), width: r.width * 0.018, height: r.height * 0.028))
        // Yan kubbeler
        p.addEllipse(in: CGRect(x: x(0.235), y: y(0.655), width: r.width * 0.12, height: r.height * 0.17))
        p.addEllipse(in: CGRect(x: x(0.645), y: y(0.655), width: r.width * 0.12, height: r.height * 0.17))
        // Minareler
        for mx in [0.12, 0.85] as [CGFloat] {
            p.addRect(CGRect(x: x(mx), y: y(0.22), width: r.width * 0.032, height: r.height * 0.71))
            p.addRect(CGRect(x: x(mx - 0.008), y: y(0.42), width: r.width * 0.048, height: r.height * 0.022))  // şerefe
            p.addRect(CGRect(x: x(mx - 0.008), y: y(0.60), width: r.width * 0.048, height: r.height * 0.022))
            p.move(to: CGPoint(x: x(mx), y: y(0.22)))
            p.addLine(to: CGPoint(x: x(mx + 0.016), y: y(0.06)))
            p.addLine(to: CGPoint(x: x(mx + 0.032), y: y(0.22)))
            p.closeSubpath()
        }
        return p
    }
}

/// Kubbenin üstündeki hilal
struct CrescentShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: r.minX + 0.482 * r.width, y: r.minY + 0.225 * r.height, width: r.width * 0.036, height: r.height * 0.075))
        p.addEllipse(in: CGRect(x: r.minX + 0.492 * r.width, y: r.minY + 0.215 * r.height, width: r.width * 0.034, height: r.height * 0.072))
        return p
    }
}

/// Gece aydınlanan pencereler
struct MosqueWindows: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width * 0.026, h = r.height * 0.075
        for cx in [0.40, 0.455, 0.545, 0.60] as [CGFloat] {
            p.addRoundedRect(in: CGRect(x: r.minX + cx * r.width - w / 2, y: r.minY + 0.79 * r.height, width: w, height: h), cornerSize: CGSize(width: w / 2, height: w / 2))
        }
        for cx in [0.29, 0.71] as [CGFloat] {
            p.addRoundedRect(in: CGRect(x: r.minX + cx * r.width - w / 2, y: r.minY + 0.82 * r.height, width: w, height: h * 0.8), cornerSize: CGSize(width: w / 2, height: w / 2))
        }
        return p
    }
}

struct PrayerSky: View {
    let phase: Int
    let ramadan: Bool
    var mosqueScale: CGFloat = 0.62   // silüetin widget yüksekliğine oranı
    var mosqueAlign: Alignment = .bottomTrailing

    private var night: Bool { phase == 5 || phase == 0 }
    private var stops: [Color] {
        switch phase {
        case 0: return [hex(0x0E1230), hex(0x3B2F63), hex(0xC0697A)]          // tan
        case 1: return [hex(0x3C78C8), hex(0x86B6E6), hex(0xF5C9A0)]          // sabah
        case 2: return [hex(0x1E6CC8), hex(0x4C9BE6), hex(0x9CCBF2)]          // öğle
        case 3: return [hex(0x3A6EA8), hex(0xC99A5B), hex(0xF0B567)]          // ikindi
        case 4: return [hex(0x2B2357), hex(0xB4495A), hex(0xF59B4F)]          // akşam
        default: return [hex(0x060A1C), hex(0x111A3E), hex(0x24305E)]        // gece
        }
    }

    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            ZStack {
                LinearGradient(colors: stops, startPoint: .top, endPoint: .bottom)
                // Yıldızlar
                if night {
                    ForEach(0..<Self.stars.count, id: \.self) { i in
                        let s = Self.stars[i]
                        Circle().fill(.white.opacity(s.2)).frame(width: s.3, height: s.3)
                            .position(x: s.0 * W, y: s.1 * H * 0.7)
                    }
                }
                // Güneş / ay
                celestial(W: W, H: H)
                // Ufuk ışığı
                RadialGradient(colors: [horizonGlow.opacity(0.55), .clear], center: .bottom, startRadius: 0, endRadius: max(W, H) * 0.7)
                // Cami silueti
                let mh = H * mosqueScale, mw = mh * 1.55
                ZStack {
                    MosqueShape().fill(silhouette)
                    CrescentShape().fill(silhouette, style: FillStyle(eoFill: true))
                    if night || phase == 4 { MosqueWindows().fill(hex(0xFFC66B).opacity(0.85)).blur(radius: 0.3) }
                }
                .frame(width: mw, height: mh)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: mosqueAlign)
                .offset(x: mosqueAlign == .bottomTrailing ? mw * 0.06 : 0, y: 1)
                // Metin okunurluğu için sol üst gölge
                LinearGradient(colors: [.black.opacity(night ? 0.0 : 0.22), .clear], startPoint: .topLeading, endPoint: .center)
            }
        }
    }

    private var horizonGlow: Color {
        switch phase { case 0: return hex(0xFF8A7A); case 1: return hex(0xFFD7A8); case 3: return hex(0xFFC36B); case 4: return hex(0xFF7A45); case 2: return hex(0xCDE7FF); default: return hex(0x3A4C8C) }
    }
    private var silhouette: Color {
        switch phase { case 5: return hex(0x02040C); case 0: return hex(0x120B26); case 4: return hex(0x1C1030); case 3: return hex(0x3A2A1E).opacity(0.85); default: return hex(0x10305A).opacity(0.7) }
    }

    @ViewBuilder private func celestial(W: CGFloat, H: CGFloat) -> some View {
        if ramadan || night {
            Image(systemName: ramadan ? "moon.stars.fill" : "moon.fill")
                .font(.system(size: H * 0.16))
                .foregroundStyle(hex(0xFFE7A3))
                .shadow(color: hex(0xFFE7A3).opacity(0.6), radius: 8)
                .rotationEffect(.degrees(-20))
                .position(x: W * 0.5, y: H * 0.2)
                .opacity(0.9)
        } else {
            let pos: CGPoint = {
                switch phase {
                case 1: return CGPoint(x: W * 0.42, y: H * 0.55)
                case 2: return CGPoint(x: W * 0.55, y: H * 0.12)
                case 3: return CGPoint(x: W * 0.62, y: H * 0.35)
                default: return CGPoint(x: W * 0.45, y: H * 0.68)   // akşam: ufukta
                }
            }()
            let col = phase == 4 ? hex(0xFFB15A) : phase == 1 ? hex(0xFFE2A8) : hex(0xFFF3C4)
            ZStack {
                Circle().fill(RadialGradient(colors: [col.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: H * 0.32)).frame(width: H * 0.64, height: H * 0.64)
                Circle().fill(col).frame(width: H * 0.13, height: H * 0.13)
            }
            .position(pos)
        }
    }

    // x, y (0–1), opaklık, boyut
    static let stars: [(CGFloat, CGFloat, Double, CGFloat)] = [
        (0.08, 0.10, 0.9, 2), (0.22, 0.30, 0.6, 1.5), (0.35, 0.08, 0.8, 1.5), (0.48, 0.42, 0.5, 1.2), (0.62, 0.15, 0.9, 2),
        (0.74, 0.36, 0.6, 1.4), (0.88, 0.08, 0.7, 1.6), (0.93, 0.48, 0.5, 1.2), (0.15, 0.55, 0.5, 1.2), (0.30, 0.70, 0.4, 1),
        (0.56, 0.62, 0.45, 1.1), (0.81, 0.62, 0.4, 1), (0.42, 0.22, 0.7, 1.3), (0.68, 0.50, 0.55, 1.2), (0.05, 0.38, 0.6, 1.4)
    ]
}

/// Geri sayım: saat varsa s:dd:ss, yoksa dd:ss
struct Countdown: View {
    let from: Date; let to: Date; var size: CGFloat
    var body: some View {
        if to > from {
            Text(timerInterval: from...to, countsDown: true)
                .font(.system(size: size, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.6)
                .multilineTextAlignment(.leading)
        } else {
            Text("0:00").font(.system(size: size, weight: .semibold, design: .rounded)).foregroundStyle(.white)
        }
    }
}
