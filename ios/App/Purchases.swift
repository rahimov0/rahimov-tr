import Foundation
import StoreKit

/// "Reklamları kaldır" tek seferlik satın alma (StoreKit 2).
@MainActor final class Purchases: ObservableObject {
    static let shared = Purchases()
    static let productID = "tr.rahimov.app.reklamsiz"

    @Published var product: Product?
    @Published var removed: Bool = Store.adsRemoved
    @Published var busy = false
    @Published var message: String?
    private var updates: Task<Void, Never>?

    func start() async {
        if updates == nil {
            updates = Task.detached { [weak self] in
                for await r in Transaction.updates {
                    if case .verified(let t) = r { await t.finish(); await self?.refresh() }
                }
            }
        }
        product = try? await Product.products(for: [Self.productID]).first
        await refresh()
    }

    func refresh() async {
        var owned = false
        for await r in Transaction.currentEntitlements {
            if case .verified(let t) = r, t.productID == Self.productID, t.revocationDate == nil { owned = true }
        }
        set(owned)
    }

    func buy() async {
        guard let p = product else { message = T("Ürün şu an yüklenemedi. Biraz sonra tekrar dene."); return }
        busy = true; defer { busy = false }
        do {
            let r = try await p.purchase()
            if case .success(let v) = r, case .verified(let t) = v { await t.finish(); set(true); message = T("Teşekkürler! Reklamlar kaldırıldı.") }
        } catch { message = T("Satın alma tamamlanamadı.") }
    }

    func restore() async {
        busy = true; defer { busy = false }
        try? await AppStore.sync()
        await refresh()
        message = removed ? T("Satın alımın geri yüklendi.") : T("Geri yüklenecek satın alım bulunamadı.")
    }

    private func set(_ v: Bool) { removed = v; Store.adsRemoved = v }
}
