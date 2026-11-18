import SwiftUI
import UIKit

struct ToxinListView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var router: Router
    @State private var category: String? = nil
    @State private var showAbout = false

    private var results: [Toxin] {
        let base = store.searchToxins(router.query)
        guard let c = category else { return base }
        return base.filter { $0.category == c }
    }

    var body: some View {
        List {
            if router.query.isEmpty && category == nil && !store.recent.isEmpty {
                Section("Recently viewed") {
                    ForEach(store.recent.prefix(5), id: \.self) { id in
                        if let t = store.toxin(id) {
                            NavigationLink(value: Route.toxin(id)) { ToxinRow(toxin: t) }
                        }
                    }
                }
            }
            Section {
                ForEach(results) { t in
                    NavigationLink(value: Route.toxin(t.id)) { ToxinRow(toxin: t) }
                }
            } header: {
                Text(category ?? (router.query.isEmpty ? "All toxins (\(store.toxins.count))" : "\(results.count) results"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Toxins")
        .searchable(text: $router.query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Toxin, drug, brand or antidote")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .overlay {
            if results.isEmpty {
                ContentUnavailableView.search(text: router.query)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("All categories") { category = nil }
                    Divider()
                    ForEach(store.categories, id: \.self) { c in
                        Button { category = c } label: {
                            if category == c { Label(c, systemImage: "checkmark") } else { Text(c) }
                        }
                    }
                } label: {
                    Image(systemName: category == nil ? "line.3.horizontal.decrease.circle"
                                                      : "line.3.horizontal.decrease.circle.fill")
                }
                .accessibilityLabel("Filter by category")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAbout = true } label: { Image(systemName: "info.circle") }
                    .accessibilityLabel("About TOXCARD")
            }
        }
        .sheet(isPresented: $showAbout) { AboutView() }
    }
}

/// One card. Agent, dose and pitfall share the screen: nothing that prevents a death sits
/// behind a tap.
struct ToxinCardView: View {
    @EnvironmentObject var store: Store
    let toxinId: String

    var body: some View {
        if let t = store.toxin(toxinId) {
            let p = store.protocolFor(t.id)
            let availability = Availability(p)
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            TierBadge(tier: p?.tier ?? "N")
                            Text(availability.label).font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.tier(p?.tier ?? "N"))
                        }
                        Text(t.category).font(.footnote).foregroundStyle(.secondary)
                        if let aka = t.aka, !aka.isEmpty {
                            Text("Also: " + aka.joined(separator: ", "))
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let line = p?.agentLine, !line.isEmpty {
                    Section("Agent") {
                        Text(line).font(.headline)
                        ForEach(store.agents(for: t.id)) { a in
                            NavigationLink(value: Route.agent(a.id)) {
                                Label(a.name, systemImage: "cross.vial")
                            }
                        }
                    }
                }

                if let dose = p?.dose, !dose.isEmpty {
                    Section {
                        ForEach(Array(dose.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                            Text(line).font(.body.monospacedDigit()).textSelection(.enabled)
                        }
                    } header: {
                        Text("Dose as published")
                    } footer: {
                        Text("Shown exactly as the cited source states it. TOXCARD does not calculate doses.")
                    }
                }

                if let pit = p?.pitfall, !pit.isEmpty {
                    Section {
                        Label {
                            Text(pit).font(.body)
                        } icon: {
                            Image(systemName: "exclamationmark.octagon.fill").foregroundStyle(Palette.pitfall)
                        }
                        .listRowBackground(Palette.pitfall.opacity(0.10))
                    } header: {
                        Text("Pitfall").foregroundStyle(Palette.pitfall)
                    }
                }

                if let w = p?.window, !w.isEmpty {
                    Section("Time window") {
                        Label(w, systemImage: "clock")
                    }
                }

                if let src = p?.sources, !src.isEmpty {
                    Section {
                        ForEach(src, id: \.self) { s in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.label).font(.footnote)
                                if let ty = s.type { Text(ty).font(.caption2).foregroundStyle(.secondary) }
                            }
                        }
                    } header: {
                        Text("Sources")
                    } footer: {
                        if let r = p?.lastReviewed { Text("Card last reviewed \(r).") }
                    }
                }

                Section {
                    PoisonCenterButton()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(t.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(item: shareText(t, p)) { Image(systemName: "square.and.arrow.up") }
                    Button {
                        store.toggleSaved(t.id)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: store.isSaved(t.id) ? "bookmark.fill" : "bookmark")
                    }
                    .accessibilityLabel(store.isSaved(t.id) ? "Remove from Saved" : "Save card")
                }
            }
            .onAppear { store.noteViewed(t.id) }
            .userActivity(CardActivity.type) { activity in
                activity.title = t.name
                activity.isEligibleForSearch = true
                activity.isEligibleForPrediction = true
                activity.userInfo = ["id": t.id]
            }
        } else {
            ContentUnavailableView("Card not found", systemImage: "questionmark.folder")
        }
    }

    private func shareText(_ t: Toxin, _ p: Protocol_?) -> String {
        var s = "\(t.name)\n"
        if let a = p?.agentLine { s += "Agent: \(a)\n" }
        if let d = p?.dose { s += "Dose (as published): \(d)\n" }
        if let f = p?.pitfall { s += "Pitfall: \(f)\n" }
        s += "Reference only. Not a substitute for a poison center (1-800-222-1222). — TOXCARD"
        return s
    }
}
