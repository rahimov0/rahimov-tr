import SwiftUI
import WebKit

extension Notification.Name { static let cityChanged = Notification.Name("rahimov.cityChanged") }

/// rahimov.tr sayfasını uygulama içinde gösterir. Site, kullanıcı aracısındaki "RahimovApp" sayesinde
/// üst menüyü ve web reklamlarını gizler; şehir ve dil uygulamanın ayarlarından aktarılır.
struct WebTab: UIViewRepresentable {
    let path: String

    func makeCoordinator() -> Coordinator { Coordinator(path: path) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.applicationNameForUserAgent = "RahimovApp/1.0"
        cfg.websiteDataStore = .default()
        cfg.userContentController.addUserScript(Coordinator.stateScript())
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
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.cityChanged), name: .cityChanged, object: nil)
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let path: String
        weak var web: WKWebView?
        init(path: String) { self.path = path }

        var homeURL: URL { URL(string: "https://rahimov.tr" + Lang.current.sitePrefix + path)! }
        func loadHome() { web?.load(URLRequest(url: homeURL)) }

        /// Sayfa yüklenmeden önce şehir ve dil tercihlerini sitenin localStorage'ına yazar.
        static func stateScript() -> WKUserScript {
            let c = Store.city
            let city = "{\"name\":\(jsonString(c.name)),\"lat\":\(c.lat),\"lon\":\(c.lon)}"
            let js = "try{localStorage.setItem('rahimov.city',\(jsonString(city)));localStorage.setItem('rahimov.geoAsked','1');localStorage.setItem('rahimov.lang','\(Lang.current.rawValue)');}catch(e){}"
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
                DispatchQueue.main.async { cachedList = list; done(list) }
            }
        }

        @objc func refresh(_ rc: UIRefreshControl) { web?.reload(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { rc.endRefreshing() } }
        @objc func cityChanged() {
            guard let web else { return }
            let ucc = web.configuration.userContentController
            ucc.removeAllUserScripts()
            ucc.addUserScript(Self.stateScript())
            web.reload()
        }

        private func isOurs(_ url: URL) -> Bool {
            guard let h = url.host?.lowercased() else { return true }
            return h == "rahimov.tr" || h == "www.rahimov.tr"
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else { return decisionHandler(.allow) }
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
