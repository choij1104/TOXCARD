import SwiftUI
import CoreSpotlight
import UIKit

enum Tab: Hashable { case toxins, signs, antidotes, saved }

enum Route: Hashable {
    case toxin(String)
    case agent(String)
    case toxidrome(String)
}

/// One place that decides what is on screen. Spotlight, Siri, quick actions and in-app taps all
/// go through it.
@MainActor
final class Router: ObservableObject {
    static let shared = Router()
    @Published var tab: Tab = .toxins
    @Published var toxinPath: [Route] = []
    @Published var signsPath: [Route] = []
    @Published var antidotePath: [Route] = []
    @Published var savedPath: [Route] = []
    @Published var query: String = ""

    func open(_ route: Route) {
        switch route {
        case .toxin:
            tab = .toxins; toxinPath = [route]
        case .agent:
            tab = .antidotes; antidotePath = [route]
        case .toxidrome:
            tab = .signs; signsPath = [route]
        }
    }

    /// "toxin:<id>", "agent:<id>", "search:<text>", "tab:signs", "tab:saved"
    func handle(_ token: String) {
        let parts = token.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return }
        switch parts[0] {
        case "toxin": open(.toxin(parts[1]))
        case "agent": open(.agent(parts[1]))
        case "search": tab = .toxins; toxinPath = []; query = parts[1]
        case "tab":
            switch parts[1] {
            case "signs": tab = .signs; signsPath = []
            case "saved": tab = .saved; savedPath = []
            case "antidotes": tab = .antidotes; antidotePath = []
            default: tab = .toxins; toxinPath = []
            }
        default: break
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let item = options.shortcutItem {
            Task { @MainActor in Router.shared.handle(item.type) }
        }
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        Task { @MainActor in Router.shared.handle(shortcutItem.type) }
        completionHandler(true)
    }
}

@main
struct ToxcardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = Store.shared
    @StateObject private var router = Router.shared
    @AppStorage("acceptedNotice") private var acceptedNotice = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .fullScreenCover(isPresented: .constant(!acceptedNotice)) {
                    NoticeView { acceptedNotice = true }
                }
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    if let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                        router.handle(id)
                    }
                }
                .onContinueUserActivity(CSQueryContinuationActionType) { activity in
                    if let q = activity.userInfo?[CSSearchQueryString] as? String {
                        router.handle("search:" + q)
                    }
                }
                .onContinueUserActivity(CardActivity.type) { activity in
                    if let id = activity.userInfo?["id"] as? String { router.handle("toxin:" + id) }
                }
                .task {
                    Spotlight.indexIfNeeded(store: store)
                    QuickActions.refresh(saved: store.saved)
                    EntryHandoff.consume(into: router)
                }
        }
    }
}

/// App Intents run before the UI may exist; they leave a token here for the UI to pick up.
enum EntryHandoff {
    @MainActor static var pending: String?
    @MainActor static func set(_ token: String) {
        pending = token
        Router.shared.handle(token)
    }
    @MainActor static func consume(into router: Router) {
        if let p = pending { router.handle(p); pending = nil }
    }
}

enum CardActivity {
    static let type = "com.hakoya.toxcard.card"
}
