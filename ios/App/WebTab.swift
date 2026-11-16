import SwiftUI
import WebKit
import WidgetKit

extension Notification.Name {
    static let cityChanged = Notification.Name("rahimov.cityChanged")
    static let switchTab = Notification.Name("rahimov.switchTab")      // object: sekme kimliği
    static let tabReselected = Notification.Name("rahimov.tabReselected") // object: sekme kimliği
}

/// Sitenin sekmelere karşılık gelen sayfaları
enum Tabs {
    static let roots: [(id: String, path: String)] = [
        ("panel", "/"), ("piyasa:doviz", "/doviz/"), ("piyasa:altin", "/altin/"), ("piyasa:kripto", "/kripto/"),
        ("hava", "/hava-durumu/"), ("namaz", "/namaz-vakitleri/"), ("daha:deprem", "/deprem/"), ("daha:tatil", "/resmi-tatiller/")]
    static func tab(forPath p: String) -> String? {
        var path = p
        for l in ["/en", "/ru", "/az"] where path == l || path.hasPrefix(l + "/") { path = String(path.dropFirst(3)); break }
        if path.isEmpty { path = "/" }
        if !path.hasSuffix("/") { path += "/" }
        if path == "/index.html/" { path = "/" }
        return roots.first { $0.path == path }?.id
    }
}

/// rahimov.tr sayfasını uygulama içinde gösterir. Site, kullanıcı aracısındaki "RahimovApp" sayesinde
/// üst menüyü ve web reklamlarını gizler; şehir ve dil uygulamanın ayarlarından aktarılır.
struct WebTab: UIViewRepresentable {
    let id: String
    let path: String

    func makeCoordinator() -> Coordinator { Coordinator(id: id, path: path) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.applicationNameForUserAgent = "RahimovApp/1.0"
        cfg.websiteDataStore = .default()
        cfg.userContentController.addUserScript(context.coordinator.stateScript())
        cfg.userContentController.add(context.coordinator, name: "rahimov")
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.navigationDelegate = context.coordinator
        wv.uiDelegate = context.coordinator
        wv.allowsBackForwardNavigationGestures = true
        wv.isOpaque = false
        wv.backgroundColor = .systemBackground
        let rc = UIRefreshControl()
        rc.addTarget(context.coordinator, action: #selector(Coordinator.refresh(_:)), for: .valueChanged)
        wv.scrollView.refreshControl = rc
        context.coordinator.web = wv
        // Uygulamada web reklamları (AdSense) yüklenmez; uygulamanın kendi AdMob banner'ı var
        Coordinator.blocker { list in
            if let list { cfg.userContentController.add(list) }
            context.coordinator.loadHome()
        }
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.cityChanged(_:)), name: .cityChanged, object: nil)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.reselected(_:)), name: .tabReselected, object: nil)
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    @MainActor final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let id: String
        let path: String
        weak var web: WKWebView?
        lazy var loc = LocationFetcher()
        init(id: String, path: String) { self.id = id; self.path = path }

        var homeURL: URL { URL(string: "https://rahimov.tr" + Lang.current.sitePrefix + path)! }
        func loadHome() { web?.load(URLRequest(url: homeURL)) }

        /// Sayfa yüklenmeden önce şehir ve dil tercihlerini sitenin localStorage'ına yazar.
        func stateScript() -> WKUserScript {
            let c = Store.city
            let city = "{\"name\":\(Self.jsonString(c.name)),\"lat\":\(c.lat),\"lon\":\(c.lon)}"
            let js = "try{localStorage.setItem('rahimov.city',\(Self.jsonString(city)));localStorage.setItem('rahimov.geoAsked','1');localStorage.setItem('rahimov.lang','\(Lang.current.rawValue)');}catch(e){}window.RAHIMOV_TAB_ROOT='\(path)';"
            return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        }
        static func jsonString(_ s: String) -> String {
            let d = try? JSONSerialization.data(withJSONObject: [s])
            let a = d.flatMap { String(data: $0, encoding: .utf8) } ?? "[\"\"]"
            return String(a.dropFirst().dropLast())
        }

        private static var cachedList: WKContentRuleList?
        static func blocker(_ done: @escaping (WKContentRuleList?) -> Void) {
            if let l = cachedList { return done(l) }
            let rules = """
            [{"trigger":{"url-filter":"googlesyndication\\\\."},"action":{"type":"block"}},{"trigger":{"url-filter":"doubleclick\\\\."},"action":{"type":"block"}},{"trigger":{"url-filter":"googleadservices\\\\."},"action":{"type":"block"}},{"trigger":{"url-filter":"adservice\\\\.google\\\\."},"action":{"type":"block"}},{"trigger":{"url-filter":"fundingchoicesmessages\\\\."},"action":{"type":"block"}}]
            """
            WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "rahimov.noads", encodedContentRuleList: rules) { list, _ in
                Task { @MainActor in cachedList = list; done(list) }
            }
        }

        @objc func reselected(_ n: Notification) {
            guard let o = n.object as? String, o == id || id.hasPrefix(o + ":"), let web else { return }
            if web.url?.path != homeURL.path || web.scrollView.contentOffset.y < 10 { loadHome() }
            else { web.scrollView.setContentOffset(.zero, animated: true) }
        }

        // Siteden gelen mesajlar: şehir seçimi ve "Konumumu kullan"
        func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let m = message.body as? [String: Any], let type = m["type"] as? String else { return }
            Task { @MainActor in
                switch type {
                case "city":
                    guard let c = m["city"] as? [String: Any], let name = c["name"] as? String,
                          let la = (c["lat"] as? NSNumber)?.doubleValue, let lo = (c["lon"] as? NSNumber)?.doubleValue else { return }
                    let city = City(name: name, lat: la, lon: lo)
                    guard city != Store.city else { return }
                    Store.city = city
                    WidgetCenter.shared.reloadAllTimelines()
                    NotificationCenter.default.post(name: .cityChanged, object: self.id)
                    await Notif.reschedule()
                case "locate":
                    loc.onFound = { c in
                        Store.city = c
                        WidgetCenter.shared.reloadAllTimelines()
                        NotificationCenter.default.post(name: .cityChanged, object: nil)
                        Task { await Notif.reschedule() }
                    }
                    loc.request()
                default: break
                }
            }
        }

        @objc func refresh(_ rc: UIRefreshControl) { web?.reload(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { rc.endRefreshing() } }
        @objc func cityChanged(_ n: Notification) {
            guard let web, (n.object as? String) != id else { return }   // değişikliği yapan sekme zaten güncel
            let ucc = web.configuration.userContentController
            ucc.removeAllUserScripts()
            ucc.addUserScript(stateScript())
            web.reload()
        }

        private func isOurs(_ url: URL) -> Bool {
            guard let h = url.host?.lowercased() else { return true }
            return h == "rahimov.tr" || h == "www.rahimov.tr"
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else { return decisionHandler(.allow) }
            // Başka bir sekmenin sayfasına giden bağlantı: o sekmeye geç
            if action.navigationType == .linkActivated, isOurs(url), let t = Tabs.tab(forPath: url.path) {
                if t != id { NotificationCenter.default.post(name: .switchTab, object: t) }
                else { loadHome() }
                return decisionHandler(.cancel)
            }
            if url.scheme == "mailto" || url.scheme == "tel" || ((url.scheme == "http" || url.scheme == "https") && !isOurs(url) && action.targetFrame?.isMainFrame != false) {
                UIApplication.shared.open(url)
                return decisionHandler(.cancel)
            }
            decisionHandler(.allow)
        }

        // target="_blank" bağlantıları: kendi sitemizse aynı görünümde, değilse Safari'de
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = action.request.url {
                if isOurs(url) { webView.load(URLRequest(url: url)) } else { UIApplication.shared.open(url) }
            }
            return nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { showOffline(webView) }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { showOffline(webView) }

        private func showOffline(_ wv: WKWebView) {
            let html = """
            <html><head><meta name='viewport' content='width=device-width,initial-scale=1'><style>
            body{font:17px -apple-system;display:flex;align-items:center;justify-content:center;height:90vh;margin:0;text-align:center;color:#57524A;background:#F2EFE8}
            @media(prefers-color-scheme:dark){body{background:#121110;color:#B5AFA4}}
            </style></head><body><div><p style='font-size:40px;margin:0'>📡</p><p>\(T("İnternet bağlantısı yok."))<br>\(T("Aşağı çekerek yenileyebilirsin."))</p></div></body></html>
            """
            wv.loadHTMLString(html, baseURL: homeURL)
        }
    }
}

extension View {
    /// Reklam kaldırılmadıysa sekmenin altına AdMob banner'ı ekler.
    @ViewBuilder func adBanner(_ show: Bool) -> some View {
        if show {
            self.safeAreaInset(edge: .bottom, spacing: 0) { BannerAd().frame(height: 50).background(.bar) }
        } else { self }
    }
}
