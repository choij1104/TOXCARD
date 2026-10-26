import UIKit
import Capacitor

/// Home Screen quick actions (touch and hold the TOXCARD icon).
/// Static actions come from Info.plist (scripts/native-setup.py): Search, Toxidrome triage.
/// Dynamic actions are the user's pinned entries, or the most recently opened ones, set from JS.
/// JS: Capacitor.registerPlugin('QuickActions')
///   setEntries({ items:[{ route, title, subtitle, icon: "saved" | "recent" }] }) -> { count: Int }
@objc(QuickActionsPlugin)
public class QuickActionsPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "QuickActionsPlugin"
    public let jsName = "QuickActions"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setEntries", returnType: CAPPluginReturnPromise)
    ]
    static let entryType = "com.hakoya.toxcard.entry"

    @objc func setEntries(_ call: CAPPluginCall) {
        let raw = (call.options["items"] as? [Any] ?? []).compactMap { $0 as? [String: Any] }
        let items: [UIApplicationShortcutItem] = raw.prefix(2).compactMap { d in
            guard let route = d["route"] as? String, route.hasPrefix("open:"),
                  let title = d["title"] as? String, !title.isEmpty else { return nil }
            let icon = (d["icon"] as? String) == "saved"
                ? UIApplicationShortcutIcon(type: .favorite)
                : UIApplicationShortcutIcon(systemImageName: "clock.arrow.circlepath")
            return UIApplicationShortcutItem(type: QuickActionsPlugin.entryType,
                                             localizedTitle: title,
                                             localizedSubtitle: d["subtitle"] as? String,
                                             icon: icon,
                                             userInfo: ["route": route as NSString])
        }
        DispatchQueue.main.async {
            UIApplication.shared.shortcutItems = items
            call.resolve(["count": items.count])
        }
    }

    /// Maps a quick action to a route. Static types are declared in Info.plist.
    static func route(for item: UIApplicationShortcutItem) -> String? {
        switch item.type {
        case "com.hakoya.toxcard.search": return "tab:search"
        case "com.hakoya.toxcard.triage": return "tab:triage"
        case "com.hakoya.toxcard.antidotes": return "tab:agents"
        case entryType: return item.userInfo?["route"] as? String
        default: return nil
        }
    }
}

extension AppDelegate {
    /// Quick action chosen while TOXCARD is running or launching (the template's
    /// didFinishLaunching returns true, so UIKit also calls this on a cold launch).
    @objc(application:performActionForShortcutItem:completionHandler:)
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        guard let r = QuickActionsPlugin.route(for: shortcutItem) else {
            completionHandler(false)
            return
        }
        EntryRouter.set(r)
        completionHandler(true)
    }
}
