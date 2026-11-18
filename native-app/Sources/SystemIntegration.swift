import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import UIKit
import AppIntents

// MARK: Spotlight

/// Indexes every toxin and antidote agent on the device so iPhone Search finds them by name,
/// synonym or brand. Rebuilt only when the dataset version changes.
enum Spotlight {
    @MainActor
    static func indexIfNeeded(store: Store) {
        let key = "spotlightVersion"
        let current = store.version?.version ?? "0"
        guard UserDefaults.standard.string(forKey: key) != current else { return }

        var items: [CSSearchableItem] = []
        for t in store.toxins {
            let attr = CSSearchableItemAttributeSet(contentType: .text)
            attr.title = t.name
            attr.contentDescription = store.protocolFor(t.id)?.agentLine ?? t.category
            attr.keywords = (t.aka ?? []) + [t.category, "poisoning", "antidote"]
            items.append(CSSearchableItem(uniqueIdentifier: "toxin:" + t.id,
                                          domainIdentifier: "toxin", attributeSet: attr))
        }
        for a in store.agents {
            let attr = CSSearchableItemAttributeSet(contentType: .text)
            attr.title = a.name
            attr.contentDescription = a.class ?? "Antidote agent"
            attr.keywords = (a.brands ?? []) + ["antidote"]
            items.append(CSSearchableItem(uniqueIdentifier: "agent:" + a.id,
                                          domainIdentifier: "agent", attributeSet: attr))
        }
        let index = CSSearchableIndex.default()
        index.deleteAllSearchableItems { _ in
            index.indexSearchableItems(items) { error in
                if error == nil {
                    DispatchQueue.main.async { UserDefaults.standard.set(current, forKey: key) }
                }
            }
        }
    }
}

// MARK: Home Screen quick actions

enum QuickActions {
    @MainActor
    static func refresh(saved: [String]) {
        var items: [UIApplicationShortcutItem] = [
            UIApplicationShortcutItem(type: "search:", localizedTitle: "Search",
                                      localizedSubtitle: nil,
                                      icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass")),
            UIApplicationShortcutItem(type: "tab:signs", localizedTitle: "Find by Signs",
                                      localizedSubtitle: "Toxidromes",
                                      icon: UIApplicationShortcutIcon(systemImageName: "eye")),
        ]
        for id in saved.prefix(2) {
            if let t = Store.shared.toxin(id) {
                items.append(UIApplicationShortcutItem(type: "toxin:" + id, localizedTitle: t.name,
                                                       localizedSubtitle: "Saved card",
                                                       icon: UIApplicationShortcutIcon(systemImageName: "bookmark.fill")))
            }
        }
        UIApplication.shared.shortcutItems = items
    }
}

// MARK: Siri and Shortcuts

struct ToxinEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Toxin"
    static var defaultQuery = ToxinQuery()
    let id: String
    let name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct ToxinQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [ToxinEntity] {
        await MainActor.run { identifiers.compactMap { id in Store.shared.toxin(id).map { ToxinEntity(id: $0.id, name: $0.name) } } }
    }
    func entities(matching string: String) async throws -> [ToxinEntity] {
        await MainActor.run { Store.shared.searchToxins(string).prefix(25).map { ToxinEntity(id: $0.id, name: $0.name) } }
    }
    func suggestedEntities() async throws -> [ToxinEntity] {
        await MainActor.run { Store.shared.toxins.map { ToxinEntity(id: $0.id, name: $0.name) } }
    }
}

struct AntidoteEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Antidote"
    static var defaultQuery = AntidoteQuery()
    let id: String
    let name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct AntidoteQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [AntidoteEntity] {
        await MainActor.run { identifiers.compactMap { id in Store.shared.agent(id).map { AntidoteEntity(id: $0.id, name: $0.name) } } }
    }
    func entities(matching string: String) async throws -> [AntidoteEntity] {
        await MainActor.run { Store.shared.searchAgents(string).prefix(25).map { AntidoteEntity(id: $0.id, name: $0.name) } }
    }
    func suggestedEntities() async throws -> [AntidoteEntity] {
        await MainActor.run { Store.shared.agents.map { AntidoteEntity(id: $0.id, name: $0.name) } }
    }
}

struct OpenToxinIntent: AppIntent {
    static var title: LocalizedStringResource = "Open a Toxin Card"
    static var description = IntentDescription("Opens a toxin card in TOXCARD: agent, dose and pitfall on one screen.")
    static var openAppWhenRun: Bool = true
    @Parameter(title: "Toxin", requestValueDialog: "Which toxin?")
    var toxin: ToxinEntity
    @MainActor
    func perform() async throws -> some IntentResult {
        EntryHandoff.set("toxin:" + toxin.id)
        return .result()
    }
}

struct OpenAntidoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Open an Antidote"
    static var description = IntentDescription("Opens an antidote in TOXCARD with every toxin it is used for.")
    static var openAppWhenRun: Bool = true
    @Parameter(title: "Antidote", requestValueDialog: "Which antidote?")
    var antidote: AntidoteEntity
    @MainActor
    func perform() async throws -> some IntentResult {
        EntryHandoff.set("agent:" + antidote.id)
        return .result()
    }
}

struct OpenSignsIntent: AppIntent {
    static var title: LocalizedStringResource = "Find by Signs"
    static var description = IntentDescription("Opens the toxidrome comparison for a patient with no history.")
    static var openAppWhenRun: Bool = true
    @MainActor
    func perform() async throws -> some IntentResult {
        EntryHandoff.set("tab:signs")
        return .result()
    }
}

struct ToxcardShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenToxinIntent(),
                    phrases: ["Open a toxin in \(.applicationName)",
                              "Open \(\.$toxin) in \(.applicationName)"],
                    shortTitle: "Toxin Card",
                    systemImageName: "exclamationmark.triangle")
        AppShortcut(intent: OpenAntidoteIntent(),
                    phrases: ["Open an antidote in \(.applicationName)",
                              "Open \(\.$antidote) in \(.applicationName)"],
                    shortTitle: "Antidote",
                    systemImageName: "cross.vial")
        AppShortcut(intent: OpenSignsIntent(),
                    phrases: ["Find by signs in \(.applicationName)"],
                    shortTitle: "Find by Signs",
                    systemImageName: "eye")
    }
}
