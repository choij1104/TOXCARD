import Foundation
import UIKit
import CoreSpotlight
import Capacitor

/// Every way into TOXCARD from outside the app lands here: a Spotlight result, "Search in App"
/// from Spotlight, a Siri / Shortcuts intent, a Home Screen quick action, or a Siri Suggestion
/// for an entry viewed earlier. Each leaves one route for the web layer to open:
///   "open:toxin:<id>"   "open:agent:<id>"   "search:<text>"   "tab:search|agents|triage|saved"
/// The route is kept in UserDefaults until the web layer takes it, so it survives a cold launch,
/// and a notification tells an already running web layer to take it now.
enum EntryRouter {
    static let key = "toxcard.pendingRoute"
    static let activityType = "com.hakoya.toxcard.entry"
    static let notification = Notification.Name("ToxcardPendingRoute")

    static func set(_ route: String) {
        UserDefaults.standard.set(route, forKey: key)
        NotificationCenter.default.post(name: notification, object: nil)
    }

    static func take() -> String {
        let v = UserDefaults.standard.string(forKey: key) ?? ""
        UserDefaults.standard.removeObject(forKey: key)
        return v
    }

    /// Called from AppDelegate's continue-userActivity (wired by scripts/native-setup.py).
    /// Spotlight item identifiers are "toxin:<id>" or "agent:<id>".
    static func handle(_ activity: NSUserActivity) -> Bool {
        switch activity.activityType {
        case CSSearchableItemActionType:
            guard let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String, !id.isEmpty else { return false }
            set("open:" + id)
            return true
        case CSQueryContinuationActionType:
            guard let q = activity.userInfo?[CSSearchQueryString] as? String else { return false }
            set("search:" + q)
            return true
        case activityType:
            guard let r = activity.userInfo?["route"] as? String, !r.isEmpty else { return false }
            set(r)
            return true
        default:
            return false
        }
    }
}

/// JS: Capacitor.registerPlugin('Launch')
///   take()                     -> { route: String }   ("" when nothing is waiting)
///   addListener('route', fn)   fired when a route arrives while the app is running
@objc(LaunchRoutePlugin)
public class LaunchRoutePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LaunchRoutePlugin"
    public let jsName = "Launch"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "take", returnType: CAPPluginReturnPromise)
    ]
    private var observer: NSObjectProtocol?

    public override func load() {
        observer = NotificationCenter.default.addObserver(forName: EntryRouter.notification, object: nil, queue: .main) { [weak self] _ in
            self?.notifyListeners("route", data: [:], retainUntilConsumed: true)
        }
    }

    deinit {
        if let o = observer { NotificationCenter.default.removeObserver(o) }
    }

    @objc func take(_ call: CAPPluginCall) {
        call.resolve(["route": EntryRouter.take()])
    }
}
