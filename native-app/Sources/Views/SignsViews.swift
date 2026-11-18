import SwiftUI

/// Find by signs: the eight toxidromes, side by side, for a patient with no history.
struct SignsView: View {
    @EnvironmentObject var store: Store
    @State private var mode = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $mode) {
                Text("Patterns").tag(0)
                Text("Compare").tag(1)
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            if mode == 0 {
                List(store.toxidromes) { tx in
                    NavigationLink(value: Route.toxidrome(tx.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tx.name).font(.headline)
                            if let tell = tx.tell {
                                Text(tell).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                CompareGrid(toxidromes: store.toxidromes)
            }
        }
        .navigationTitle("Find by Signs")
    }
}

private struct CompareGrid: View {
    let toxidromes: [Toxidrome]
    private let rows: [(String, KeyPath<Toxidrome, String?>)] = [
        ("Pupils", \.pupils), ("Skin", \.skin), ("Vitals", \.vitals),
        ("Mental status", \.mental), ("Onset", \.onset),
    ]

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Grid(alignment: .topLeading, horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow {
                    Text("").frame(width: 96)
                    ForEach(toxidromes) { tx in
                        NavigationLink(value: Route.toxidrome(tx.id)) {
                            Text(tx.name).font(.subheadline.weight(.bold))
                                .frame(width: 170, alignment: .leading)
                                .padding(8)
                        }
                        .background(Color.accentColor.opacity(0.12))
                    }
                }
                ForEach(rows, id: \.0) { row in
                    GridRow {
                        Text(row.0).font(.caption.weight(.semibold))
                            .frame(width: 96, alignment: .leading).padding(8)
                            .background(Color(.secondarySystemBackground))
                        ForEach(toxidromes) { tx in
                            Text(tx[keyPath: row.1] ?? "—").font(.caption)
                                .frame(width: 170, alignment: .leading).padding(8)
                                .background(Color(.systemBackground))
                        }
                    }
                }
            }
            .background(Color(.separator))
            .padding()
        }
    }
}

struct ToxidromeDetailView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var router: Router
    let toxidromeId: String

    var body: some View {
        if let tx = store.toxidromes.first(where: { $0.id == toxidromeId }) {
            List {
                if let tell = tx.tell {
                    Section("The tell") {
                        Label(tell, systemImage: "lightbulb").font(.body.weight(.medium))
                    }
                }
                Section("Findings") {
                    row("Pupils", tx.pupils)
                    row("Skin", tx.skin)
                    row("Vitals", tx.vitals)
                    row("Mental status", tx.mental)
                    row("Onset", tx.onset)
                }
                if let agents = tx.agents, !agents.isEmpty {
                    Section {
                        ForEach(agents, id: \.self) { name in
                            Button {
                                router.handle("search:" + searchTerm(name))
                            } label: {
                                HStack {
                                    Text(name).foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Common causes")
                    } footer: {
                        Text("Tap a cause to search the toxin cards.")
                    }
                }
                Section { PoisonCenterButton().listRowInsets(EdgeInsets()).listRowBackground(Color.clear) }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(tx.name)
        }
    }

    @ViewBuilder private func row(_ label: String, _ value: String?) -> some View {
        if let v = value, !v.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(v)
            }
        }
    }

    /// First word group before any parenthesis, e.g. "Certain mushrooms (Clitocybe)" -> "Certain mushrooms".
    private func searchTerm(_ s: String) -> String {
        let base = s.components(separatedBy: "(").first ?? s
        let words = base.split(separator: " ").prefix(2)
        return words.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
}
