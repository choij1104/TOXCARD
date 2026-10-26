import Foundation
import UIKit
import CoreSpotlight
import UniformTypeIdentifiers
import Capacitor

/// One reference entry as the native side knows it: enough to show it in Spotlight and Siri and
/// to open it. The clinical text itself stays in the web layer and is never copied here.
struct CatalogEntry: Codable {
    let id: String
    let kind: String          // "toxin" | "agent"
    let title: String
    let subtitle: String
    let keywords: [String]
}

/// The list of entries Siri and Shortcuts can resolve. The web layer sends the current list with
/// every Spotlight index; before the app has ever run, the list is read from the data files that
/// ship inside the app (public/data/toxins.json and public/data/antidote-agents.json).
enum EntryCatalog {
    static let key = "toxcard.catalog"

    static func save(_ entries: [CatalogEntry]) {
        if let d = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(d, forKey: key) }
    }

    static func load() -> [CatalogEntry] {
        if let d = UserDefaults.standard.data(forKey: key),
           let e = try? JSONDecoder().decode([CatalogEntry].self, from: d), !e.isEmpty {
            return e
        }
        return bundled()
    }

    private static func json(_ name: String) -> [[String: Any]] {
        guard let base = Bundle.main.url(forResource: "public", withExtension: nil),
              let data = try? Data(contentsOf: base.appendingPathComponent("data").appendingPathComponent(name)),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return arr
    }

    private static func bundled() -> [CatalogEntry] {
        let toxins = json("toxins.json").compactMap { t -> CatalogEntry? in
            guard let id = t["id"] as? String, let name = t["name"] as? String else { return nil }
            let cat = t["category"] as? String ?? ""
            return CatalogEntry(id: id, kind: "toxin", title: name, subtitle: cat,
                                keywords: (t["aka"] as? [String] ?? []) + [cat])
        }
        let agents = json("antidote-agents.json").compactMap { a -> CatalogEntry? in
            guard let id = a["id"] as? String, let name = a["name"] as? String else { return nil }
            let cls = a["class"] as? String ?? ""
            return CatalogEntry(id: id, kind: "agent", title: name, subtitle: cls,
                                keywords: (a["brands"] as? [String] ?? []) + [cls])
        }
        return toxins + agents
    }

    /// Case- and accent-insensitive match on the title, then on keywords (synonyms, brands).
    static func search(_ text: String, kind: String) -> [CatalogEntry] {
        let all = load().filter { $0.kind == kind }
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return all }
        let opts: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let byTitle = all.filter { $0.title.range(of: q, options: opts) != nil }
        let byKeyword = all.filter { e in
            e.title.range(of: q, options: opts) == nil && e.keywords.contains { $0.range(of: q, options: opts) != nil }
        }
        return byTitle + byKeyword
    }
}

/// Puts every toxin and antidote into iPhone Search (Core Spotlight). Tapping a result opens the
/// entry (EntryRouter). The entry open on screen is also offered to Siri Suggestions.
/// JS: Capacitor.registerPlugin('Spotlight')
///   index({ version, items:[{ id, kind, title, subtitle, keywords }] }) -> { indexed: Int, available: Bool }
///   clear()                                                            -> {}
///   viewing({ id, kind, title, subtitle })                             -> {}
@objc(SpotlightPlugin)
public class SpotlightPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "SpotlightPlugin"
    public let jsName = "Spotlight"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "index", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clear", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "viewing", returnType: CAPPluginReturnPromise)
    ]
    static let domain = "com.hakoya.toxcard.entries"
    private var current: NSUserActivity?

    private func entries(_ call: CAPPluginCall) -> [CatalogEntry] {
        let raw = (call.options["items"] as? [Any] ?? []).compactMap { $0 as? [String: Any] }
        return raw.compactMap { d in
            guard let id = d["id"] as? String, let kind = d["kind"] as? String,
                  let title = d["title"] as? String, kind == "toxin" || kind == "agent" else { return nil }
            let words = (d["keywords"] as? [Any] ?? []).compactMap { $0 as? String }.filter { !$0.isEmpty }
            return CatalogEntry(id: id, kind: kind, title: title, subtitle: d["subtitle"] as? String ?? "", keywords: words)
        }
    }

    private func attributes(_ e: CatalogEntry) -> CSSearchableItemAttributeSet {
        let a = CSSearchableItemAttributeSet(contentType: UTType.text)
        a.title = e.title
        a.displayName = e.title
        a.contentDescription = e.subtitle
        a.keywords = e.keywords + [e.kind == "agent" ? "antidote" : "toxin", "TOXCARD"]
        return a
    }

    @objc func index(_ call: CAPPluginCall) {
        let list = entries(call)
        EntryCatalog.save(list)
        ToxcardShortcutsUpdater.refresh()
        guard CSSearchableIndex.isIndexingAvailable() else {
            call.resolve(["indexed": 0, "available": false])
            return
        }
        let items = list.map { e -> CSSearchableItem in
            let item = CSSearchableItem(uniqueIdentifier: e.kind + ":" + e.id,
                                        domainIdentifier: SpotlightPlugin.domain + "." + e.kind,
                                        attributeSet: attributes(e))
            item.expirationDate = Date.distantFuture
            return item
        }
        let index = CSSearchableIndex.default()
        index.deleteSearchableItems(withDomainIdentifiers: [SpotlightPlugin.domain]) { _ in
            index.indexSearchableItems(items) { error in
                if let error = error {
                    call.reject(error.localizedDescription)
                } else {
                    call.resolve(["indexed": items.count, "available": true])
                }
            }
        }
    }

    @objc func clear(_ call: CAPPluginCall) {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [SpotlightPlugin.domain]) { _ in
            call.resolve()
        }
    }

    @objc func viewing(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let kind = call.getString("kind"), let title = call.getString("title") else {
            call.reject("id, kind and title are required.")
            return
        }
        let subtitle = call.getString("subtitle") ?? ""
        DispatchQueue.main.async {
            let act = NSUserActivity(activityType: EntryRouter.activityType)
            act.title = title
            act.userInfo = ["route": "open:\(kind):\(id)"]
            act.isEligibleForSearch = true
            act.isEligibleForPrediction = true
            act.persistentIdentifier = kind + ":" + id
            let a = CSSearchableItemAttributeSet(contentType: UTType.text)
            a.contentDescription = subtitle
            a.relatedUniqueIdentifier = kind + ":" + id
            act.contentAttributeSet = a
            self.current?.invalidate()
            self.current = act
            self.bridge?.viewController?.userActivity = act
            act.becomeCurrent()
            call.resolve()
        }
    }
}
