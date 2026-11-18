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
                            HStack(spacing: 12) {
                                Image(systemName: "syringe").font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Palette.acc)
                                    .frame(width: 30, height: 30)
                                    .background(Palette.accSoft, in: RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(a.name).font(.system(size: 16.5, weight: .medium)).foregroundStyle(Palette.ink)
                                    Text(subtitle(a)).font(.system(size: 13.5)).foregroundStyle(Palette.mut).lineLimit(1)
                                }
                            }
                        }
                        .listRowBackground(Palette.surface)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Palette.ground)
        .navigationTitle("Antidotes")
        .searchable(text: $query, prompt: "Agent or brand name")
        .autocorrectionDisabled()
        .overlay { if results.isEmpty { ContentUnavailableView.search(text: query) } }
    }

    private func subtitle(_ a: Agent) -> String {
        let n = store.toxins(treatedBy: a.id).count
        return "\(a.class ?? "Agent") · \(n) \(n == 1 ? "toxin" : "toxins")"
    }
}

struct AgentDetailView: View {
    @EnvironmentObject var store: Store
    let agentId: String

    var body: some View {
        if let a = store.agent(agentId) {
            let treated = store.toxins(treatedBy: a.id)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Panel(top: Palette.acc) {
                        HStack(alignment: .top, spacing: 13) {
                            Image(systemName: "syringe").font(.system(size: 25, weight: .semibold))
                                .foregroundStyle(Palette.acc)
                                .frame(width: 46, height: 46)
                                .background(Palette.accSoft, in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(a.name).font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
                                HStack(spacing: 6) {
                                    if let c = a.class { Pill(text: c, fg: Palette.acc, bg: Palette.accSoft) }
                                    Pill(text: "\(treated.count) \(treated.count == 1 ? "toxin" : "toxins")")
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                    if let b = a.brands, !b.isEmpty {
                        Panel {
                            PanelLabel(text: "Also known as")
                            Text(b.joined(separator: ", ")).font(.system(size: 16)).foregroundStyle(Palette.ink)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        PanelLabel(text: "Used for").padding(.horizontal, 4)
                        VStack(spacing: 0) {
                            ForEach(Array(treated.enumerated()), id: \.element.id) { i, t in
                                if i > 0 { Divider().padding(.leading, 56) }
                                NavigationLink(value: Route.toxin(t.id)) {
                                    HStack {
                                        ToxinRow(toxin: t)
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(Palette.dim)
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        Text("Open a toxin for the dose and pitfall of that indication.")
                            .font(.system(size: 12.5)).foregroundStyle(Palette.dim).padding(.horizontal, 4)
                    }
                }
                .padding(16)
            }
            .background(Palette.ground)
            .navigationTitle(a.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Agent not found", systemImage: "questionmark.folder")
        }
    }
}
