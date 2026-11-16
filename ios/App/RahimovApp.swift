import SwiftUI
import WidgetKit
import BackgroundTasks

@main
struct RahimovApp: App {
    @Environment(\.scenePhase) private var phase
    @StateObject private var purchases = Purchases.shared
    @State private var tab = "panel"

    var body: some Scene {
        WindowGroup {
            RootView(tab: $tab)
                .environmentObject(purchases)
                .onOpenURL { url in if let h = url.host, ["panel", "doviz", "hava", "namaz"].contains(h) { tab = h } }
                .task {
                    await purchases.start()
                    Ads.startAfterConsent()
                    await Notif.reschedule()
                    scheduleRefresh()
                }
        }
        .onChange(of: phase) { _, p in
            if p == .active { Task { await Notif.reschedule(); WidgetCenter.shared.reloadAllTimelines() } }
            if p == .background { scheduleRefresh() }
        }
        .backgroundTask(.appRefresh("tr.rahimov.app.refresh")) {
            await Notif.reschedule()
            WidgetCenter.shared.reloadAllTimelines()
            await MainActor.run { scheduleRefresh() }
        }
    }
}

func scheduleRefresh() {
    let r = BGAppRefreshTaskRequest(identifier: "tr.rahimov.app.refresh")
    r.earliestBeginDate = Date().addingTimeInterval(6 * 3600)
    try? BGTaskScheduler.shared.submit(r)
}

struct RootView: View {
    @Binding var tab: String
    @EnvironmentObject var purchases: Purchases
    var body: some View {
        TabView(selection: $tab) {
            WebTab(path: "/").adBanner(!purchases.removed)
                .tabItem { Label(T("Panel"), systemImage: "square.grid.2x2.fill") }.tag("panel")
            WebTab(path: "/doviz/").adBanner(!purchases.removed)
                .tabItem { Label(T("Döviz"), systemImage: "turkishlirasign.circle.fill") }.tag("doviz")
            WebTab(path: "/hava-durumu/").adBanner(!purchases.removed)
                .tabItem { Label(T("Hava"), systemImage: "cloud.sun.fill") }.tag("hava")
            WebTab(path: "/namaz-vakitleri/").adBanner(!purchases.removed)
                .tabItem { Label(T("Namaz"), systemImage: "moon.stars.fill") }.tag("namaz")
            SettingsView()
                .tabItem { Label(T("Ayarlar"), systemImage: "gearshape.fill") }.tag("ayarlar")
        }
        .tint(Color(red: 0.76, green: 0.25, blue: 0.05))
    }
}
