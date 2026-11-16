import SwiftUI
import UIKit
import GoogleMobileAds
import AppTrackingTransparency

/// AdMob. Kimlikler Info.plist'ten okunur; gerçek kimlikler gelene kadar Google'ın test kimlikleri kullanılır.
enum Ads {
    static var bannerUnitID: String {
        (Bundle.main.object(forInfoDictionaryKey: "AdBannerUnitID") as? String) ?? "ca-app-pub-3940256099942544/2435281174"
    }
    private static var started = false

    /// Önce Apple'ın izleme izni sorulur, sonra reklam SDK'sı başlatılır (izin verilmese de kişiselleştirilmemiş reklam gösterilir).
    @MainActor static func startAfterConsent() {
        guard !started, !Store.adsRemoved else { return }
        started = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async { MobileAds.shared.start(completionHandler: nil) }
            }
        }
    }
}

struct BannerAd: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let host = UIView()
        let width = UIScreen.main.bounds.width
        let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: width))
        banner.adUnitID = Ads.bannerUnitID
        banner.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(banner)
        NSLayoutConstraint.activate([banner.centerXAnchor.constraint(equalTo: host.centerXAnchor), banner.centerYAnchor.constraint(equalTo: host.centerYAnchor)])
        DispatchQueue.main.async {
            banner.rootViewController = host.window?.rootViewController ?? UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
            banner.load(Request())
        }
        return host
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
