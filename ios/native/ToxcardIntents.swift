import Foundation
#if canImport(AppIntents)
import AppIntents
#endif

/// Siri, Spotlight and the Shortcuts app (App Intents iOS 16+, App Shortcuts iOS 17+).
/// "Look up an antidote in TOXCARD" / "Look up a toxin in TOXCARD" ask which entry, resolve it
/// against EntryCatalog (title, synonyms, brand names), then open TOXCARD on that card through
/// EntryRouter. Nothing is read aloud or summarised: the card opens on screen, pitfall included.
enum ToxcardShortcutsUpdater {
    /// Tells the system the entity list changed so parameterised phrases pick up new names.
    static func refresh() {
        #if canImport(AppIntents)
        if #available(iOS 17.0, *) {
            ToxcardShortcuts.updateAppShortcutParameters()
        }
        #endif
    }
}

#if canImport(AppIntents)
@available(iOS 16.0, *)
struct ToxinEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Toxin"
    static var defaultQuery = ToxinQuery()
    let id: String
    let title: String
    let subtitle: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }
    init(_ e: CatalogEntry) { id = e.id; title = e.title; subtitle = e.subtitle }
}

@available(iOS 16.0, *)
struct ToxinQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [ToxinEntity] {
        let all = EntryCatalog.load().filter { $0.kind == "toxin" }
        return identifiers.compactMap { id in all.first { $0.id == id }.map(ToxinEntity.init) }
    }
    func entities(matching string: String) async throws -> [ToxinEntity] {
        EntryCatalog.search(string, kind: "toxin").prefix(25).map(ToxinEntity.init)
    }
    func suggestedEntities() async throws -> [ToxinEntity] {
        EntryCatalog.search("", kind: "toxin").map(ToxinEntity.init)
    }
}

@available(iOS 16.0, *)
struct AntidoteEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Antidote"
    static var defaultQuery = AntidoteQuery()
    let id: String
    let title: String
    let subtitle: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }
    init(_ e: CatalogEntry) { id = e.id; title = e.title; subtitle = e.subtitle }
}

@available(iOS 16.0, *)
struct AntidoteQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [AntidoteEntity] {
        let all = EntryCatalog.load().filter { $0.kind == "agent" }
        return identifiers.compactMap { id in all.first { $0.id == id }.map(AntidoteEntity.init) }
    }
    func entities(matching string: String) async throws -> [AntidoteEntity] {
        EntryCatalog.search(string, kind: "agent").prefix(25).map(AntidoteEntity.init)
    }
    func suggestedEntities() async throws -> [AntidoteEntity] {
        EntryCatalog.search("", kind: "agent").map(AntidoteEntity.init)
    }
}

@available(iOS 16.0, *)
struct LookUpAntidoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Look Up an Antidote"
    static var description = IntentDescription("Opens an antidote in TOXCARD with every toxin it is used for.")
    static var openAppWhenRun: Bool = true
    @Parameter(title: "Antidote", requestValueDialog: "Which antidote?")
    var antidote: AntidoteEntity
    static var parameterSummary: some ParameterSummary {
        Summary("Look up \(\.$antidote)")
    }
    @MainActor
    func perform() async throws -> some IntentResult {
        EntryRouter.set("open:agent:" + antidote.id)
        return .result()
    }
}

@available(iOS 16.0, *)
struct LookUpToxinIntent: AppIntent {
    static var title: LocalizedStringResource = "Look Up a Toxin"
    static var description = IntentDescription("Opens a toxin card in TOXCARD: agent, dose and pitfall on one screen.")
    static var openAppWhenRun: Bool = true
    @Parameter(title: "Toxin", requestValueDialog: "Which toxin?")
    var toxin: ToxinEntity
    static var parameterSummary: some ParameterSummary {
        Summary("Look up \(\.$toxin)")
    }
    @MainActor
    func perform() async throws -> some IntentResult {
        EntryRouter.set("open:toxin:" + toxin.id)
        return .result()
    }
}

@available(iOS 16.0, *)
struct SearchToxcardIntent: AppIntent {
    static var title: LocalizedStringResource = "Search TOXCARD"
    static var description = IntentDescription("Opens TOXCARD with a search for a toxin, antidote or brand name.")
    static var openAppWhenRun: Bool = true
    @Parameter(title: "Search for", requestValueDialog: "What should TOXCARD search for?")
    var text: String
    @MainActor
    func perform() async throws -> some IntentResult {
        EntryRouter.set("search:" + text)
        return .result()
    }
}

@available(iOS 16.0, *)
struct OpenTriageIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Toxidrome Triage"
    static var description = IntentDescription("Opens the eight toxidrome patterns for a patient with no history.")
    static var openAppWhenRun: Bool = true
    @MainActor
    func perform() async throws -> some IntentResult {
        EntryRouter.set("tab:triage")
        return .result()
    }
}

@available(iOS 17.0, *)
struct ToxcardShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LookUpAntidoteIntent(),
                    phrases: ["Look up an antidote in \(.applicationName)",
                              "Look up \(\.$antidote) in \(.applicationName)",
                              "Open \(\.$antidote) in \(.applicationName)"],
                    shortTitle: "Look Up Antidote",
                    systemImageName: "cross.vial")
        AppShortcut(intent: LookUpToxinIntent(),
                    phrases: ["Look up a toxin in \(.applicationName)",
                              "Look up \(\.$toxin) in \(.applicationName)",
                              "Open \(\.$toxin) in \(.applicationName)"],
                    shortTitle: "Look Up Toxin",
                    systemImageName: "exclamationmark.triangle")
        AppShortcut(intent: OpenTriageIntent(),
                    phrases: ["Open toxidrome triage in \(.applicationName)",
                              "Start toxidrome triage in \(.applicationName)"],
                    shortTitle: "Toxidrome Triage",
                    systemImageName: "stethoscope")
        AppShortcut(intent: SearchToxcardIntent(),
                    phrases: ["Search \(.applicationName)"],
                    shortTitle: "Search",
                    systemImageName: "magnifyingglass")
    }
}
#endif
