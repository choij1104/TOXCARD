import SwiftUI

struct AgentListView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""

    var body: some View {
        let results = store.searchAgents(query)
        let grouped = Dictionary(grouping: results) { String($0.name.prefix(1)).uppercased() }
        let letters = grouped.keys.sorted()
        List {
            ForEach(letters, id: \.self) { letter in
                Section(letter) {
                    ForEach(grouped[letter] ?? []) { a in
                        NavigationLink(value: Route.agent(a.id)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(a.name).font(.body.weight(.semibold))
                                Text(subtitle(a)).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Antidotes")
        .searchable(text: $query, prompt: "Agent or brand name")
        .autocorrectionDisabled()
        .overlay { if results.isEmpty { ContentUnavailableView.search(text: query) } }
    }

    private func subtitle(_ a: Agent) -> String {
        let n = store.toxins(treatedBy: a.id).count
        let cls = a.class ?? "Agent"
        return "\(cls) · \(n) \(n == 1 ? "toxin" : "toxins")"
    }
}

struct AgentDetailView: View {
    @EnvironmentObject var store: Store
    let agentId: String

    var body: some View {
        if let a = store.agent(agentId) {
            let treated = store.toxins(treatedBy: a.id)
            List {
                Section {
                    if let c = a.class { LabeledContent("Class", value: c) }
                    if let b = a.brands, !b.isEmpty {
                        LabeledContent("Also known as", value: b.joined(separator: ", "))
                    }
                }
                Section {
                    ForEach(treated) { t in
                        NavigationLink(value: Route.toxin(t.id)) { ToxinRow(toxin: t) }
                    }
                } header: {
                    Text("Used for \(treated.count) \(treated.count == 1 ? "toxin" : "toxins")")
                } footer: {
                    Text("Open a toxin to see the dose and pitfall for that indication.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(a.name)
        } else {
            ContentUnavailableView("Agent not found", systemImage: "questionmark.folder")
        }
    }
}
