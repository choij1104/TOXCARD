import Foundation
import SwiftUI

/// The whole dataset, loaded once from the app bundle. Nothing is fetched from a network.
@MainActor
final class Store: ObservableObject {
    static let shared = Store()

    let toxins: [Toxin]
    let agents: [Agent]
    let toxidromes: [Toxidrome]
    let version: DatasetVersion?
    private let protocolByToxin: [String: Protocol_]
    private let toxinById: [String: Toxin]
    private let agentById: [String: Agent]
    private let searchText: [String: String]   // id -> lowercased haystack

    @Published private(set) var saved: [String] = []    // toxin ids, newest first
    @Published private(set) var recent: [String] = []   // toxin ids, newest first

    private init() {
        func load<T: Decodable>(_ name: String) -> T? {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
        }
        let t: [Toxin] = load("toxins") ?? []
        let a: [Agent] = load("antidote-agents") ?? []
        let p: [Protocol_] = load("protocols") ?? []
        toxins = t.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        agents = a.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        toxidromes = load("toxidromes") ?? []
        version = load("version")
        protocolByToxin = Dictionary(p.map { ($0.toxinId, $0) }, uniquingKeysWith: { a, _ in a })
        toxinById = Dictionary(t.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        agentById = Dictionary(a.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        var hay: [String: String] = [:]
        for x in t {
            let pr = protocolByToxin[x.id]
            hay[x.id] = ([x.name, x.category, pr?.agentLine ?? ""] + (x.aka ?? [])).joined(separator: " ").lowercased()
        }
        for x in a {
            hay["agent:" + x.id] = ([x.name, x.class ?? ""] + (x.brands ?? [])).joined(separator: " ").lowercased()
        }
        searchText = hay

        let d = UserDefaults.standard
        saved = d.stringArray(forKey: "saved") ?? []
        recent = d.stringArray(forKey: "recent") ?? []
    }

    // MARK: lookups
    func toxin(_ id: String) -> Toxin? { toxinById[id] }
    func agent(_ id: String) -> Agent? { agentById[id] }
    func protocolFor(_ toxinId: String) -> Protocol_? { protocolByToxin[toxinId] }

    func agents(for toxinId: String) -> [Agent] {
        (protocolByToxin[toxinId]?.antidoteIds ?? []).compactMap { agentById[$0] }
    }

    func toxins(treatedBy agentId: String) -> [Toxin] {
        let ids = Set(agentById[agentId]?.treats ?? [])
            .union(protocolByToxin.values.filter { $0.antidoteIds.contains(agentId) }.map(\.toxinId))
        return ids.compactMap { toxinById[$0] }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var categories: [String] {
        Array(Set(toxins.map(\.category))).sorted()
    }

    // MARK: search
    private func tokens(_ q: String) -> [String] {
        q.lowercased().split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init)
    }

    func searchToxins(_ q: String) -> [Toxin] {
        let words = tokens(q)
        guard !words.isEmpty else { return toxins }
        let hits = toxins.filter { t in
            let h = searchText[t.id] ?? ""
            return words.allSatisfy { h.contains($0) }
        }
        // Names that start with the query come first.
        let first = words[0]
        return hits.sorted { a, b in
            let ap = a.name.lowercased().hasPrefix(first), bp = b.name.lowercased().hasPrefix(first)
            if ap != bp { return ap }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    func searchAgents(_ q: String) -> [Agent] {
        let words = tokens(q)
        guard !words.isEmpty else { return agents }
        return agents.filter { a in
            let h = searchText["agent:" + a.id] ?? ""
            return words.allSatisfy { h.contains($0) }
        }
    }

    // MARK: saved and recent (on device only)
    func isSaved(_ id: String) -> Bool { saved.contains(id) }

    func toggleSaved(_ id: String) {
        if let i = saved.firstIndex(of: id) { saved.remove(at: i) } else { saved.insert(id, at: 0) }
        UserDefaults.standard.set(saved, forKey: "saved")
        QuickActions.refresh(saved: saved)
    }

    func removeSaved(at offsets: IndexSet) {
        saved.remove(atOffsets: offsets)
        UserDefaults.standard.set(saved, forKey: "saved")
        QuickActions.refresh(saved: saved)
    }

    func noteViewed(_ id: String) {
        recent.removeAll { $0 == id }
        recent.insert(id, at: 0)
        if recent.count > 20 { recent.removeLast(recent.count - 20) }
        UserDefaults.standard.set(recent, forKey: "recent")
    }

    func clearRecent() {
        recent = []
        UserDefaults.standard.set(recent, forKey: "recent")
    }
}
