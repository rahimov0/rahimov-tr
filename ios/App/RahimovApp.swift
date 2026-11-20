import SwiftUI
import WidgetKit
import BackgroundTasks

@main
struct RahimovApp: App {
    @Environment(\.scenePhase) private var phase
    @State private var tab = "panel"
    @State private var backgroundAt: Date?

    var body: some Scene {
        WindowGroup {
            RootView(tab: $tab)
                .onOpenURL { url in
                    switch url.host {
                    case "doviz": NotificationCenter.default.post(name: .switchTab, object: "piyasa:doviz")
                    case "panel", "hava", "namaz": tab = url.host!
                    case "kible": tab = "namaz"; NotificationCenter.default.post(name: .openQibla, object: nil)
                    default: break
                    }
                }
                .task {
                    AutoLocation.shared.refresh()
                    await Notif.reschedule()
                    scheduleRefresh()
                }
        }
        .onChange(of: phase) { _, p in
            if p == .active, Qibla.pendingOpen {
                Qibla.pendingOpen = false; tab = "namaz"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { NotificationCenter.default.post(name: .openQibla, object: nil) }
            }
            if p == .active { AutoLocation.shared.refresh(); Task { await Notif.reschedule(); WidgetCenter.shared.reloadAllTimelines() } }
            if p == .active, let b = backgroundAt {
                NotificationCenter.default.post(name: .appResumed, object: Date().timeIntervalSince(b))
                backgroundAt = nil
            }
            if p == .background { backgroundAt = Date(); scheduleRefresh() }
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
    @State private var market = "doviz"
    @State private var morePath: [String] = []
    @State private var showCity = false
    @State private var showQibla = false

    var body: some View {
        // Seçili sekmeye tekrar dokununca sekme kendi ana sayfasına döner
        let sel = Binding<String>(get: { tab }, set: { v in
            if v == tab {
                NotificationCenter.default.post(name: .tabReselected, object: v)
                if v == "daha" { morePath = [] }
            }
            tab = v
        })
        TabView(selection: sel) {
            WebTab(id: "panel", path: "/")
                .tabItem { Label(T("Panel"), systemImage: "square.grid.2x2.fill") }.tag("panel")
            MarketTab(segment: $market)
                .tabItem { Label(T("Piyasa"), systemImage: "chart.line.uptrend.xyaxis") }.tag("piyasa")
            WebTab(id: "hava", path: "/hava-durumu/")
                .tabItem { Label(T("Hava"), systemImage: "cloud.sun.fill") }.tag("hava")
            WebTab(id: "namaz", path: "/namaz-vakitleri/")
                .tabItem { Label(T("Namaz"), systemImage: "moon.stars.fill") }.tag("namaz")
            SettingsView(path: $morePath)
                .tabItem { Label(T("Daha fazla"), systemImage: "ellipsis.circle.fill") }.tag("daha")
        }
        .tint(Color(red: 0.76, green: 0.25, blue: 0.05))
        .sheet(isPresented: $showCity) { CityPickerSheet() }
        .onReceive(NotificationCenter.default.publisher(for: .pickCity)) { _ in showCity = true }
        .fullScreenCover(isPresented: $showQibla) { QiblaView() }
        .onReceive(NotificationCenter.default.publisher(for: .openQibla)) { _ in showCity = false; showQibla = true }
        .onReceive(NotificationCenter.default.publisher(for: .switchTab)) { n in
            guard let t = n.object as? String else { return }
            let parts = t.split(separator: ":").map(String.init)
            tab = parts[0]
            if parts[0] == "piyasa", parts.count > 1 { market = parts[1] }
            if parts[0] == "daha", parts.count > 1 { morePath = [parts[1]] }
        }
    }
}

/// Piyasa: üstte Döviz | Altın | Kripto geçişi; her biri kendi sayfasını korur
struct MarketTab: View {
    @Binding var segment: String
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $segment) {
                Text(T("Döviz")).tag("doviz")
                Text(T("Altın")).tag("altin")
                Text(T("Kripto")).tag("kripto")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color(uiColor: .systemBackground))
            ZStack {
                WebTab(id: "piyasa:doviz", path: "/doviz/").opacity(segment == "doviz" ? 1 : 0).allowsHitTesting(segment == "doviz")
                WebTab(id: "piyasa:altin", path: "/altin/").opacity(segment == "altin" ? 1 : 0).allowsHitTesting(segment == "altin")
                WebTab(id: "piyasa:kripto", path: "/kripto/").opacity(segment == "kripto" ? 1 : 0).allowsHitTesting(segment == "kripto")
            }
        }
    }
}
