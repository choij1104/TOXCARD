import SwiftUI
import UIKit

struct ToxinListView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var router: Router
    @State private var category: String? = nil

    private var results: [Toxin] {
        let base = store.searchToxins(router.query)
        guard let c = category else { return base }
        return base.filter { $0.category == c }
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        chip("All", selected: category == nil) { category = nil }
                        ForEach(store.categories, id: \.self) { c in
                            chip(c, selected: category == c) { category = (category == c ? nil : c) }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 2)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            Section {
                ForEach(results) { t in
                    NavigationLink(value: Route.toxin(t.id)) { ToxinRow(toxin: t) }
                        .listRowBackground(Palette.surface)
                }
            } header: {
                Text(category ?? (router.query.isEmpty ? "All toxins · \(store.toxins.count)" : "\(results.count) results"))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Palette.ground)
        .navigationTitle("Toxins")
        .searchable(text: $router.query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Toxin, drug, brand or antidote")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .overlay { if results.isEmpty { ContentUnavailableView.search(text: router.query) } }
    }

    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 13).frame(minHeight: 34)
                .foregroundStyle(selected ? Palette.surface : Palette.ink)
                .background(selected ? Palette.acc : Palette.surface, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// One card, 1.1 layout: hero with the tier tab, then window, agent, dose, pitfall and sources as
/// separate panels. Agent, dose and pitfall share the screen; nothing that prevents a death sits
/// behind a tap.
struct ToxinCardView: View {
    @EnvironmentObject var store: Store
    let toxinId: String

    var body: some View {
        if let t = store.toxin(toxinId) {
            let p = store.protocolFor(t.id)
            let tier = p?.tier ?? "N"
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    hero(t, p, tier)
                    if let w = p?.window, !w.isEmpty {
                        Panel(background: Palette.amberSoft) {
                            PanelLabel(text: "Time-critical window", color: Palette.amber)
                            Text(w).font(.system(size: 16.5)).foregroundStyle(Palette.ink)
                        }
                    }
                    if let line = p?.agentLine, !line.isEmpty {
                        Panel(leading: Palette.acc) {
                            PanelLabel(text: "Agent")
                            Text(line).font(.system(size: 18, weight: .semibold)).foregroundStyle(Palette.acc)
                            let agents = store.agents(for: t.id)
                            if !agents.isEmpty {
                                FlowChips(items: agents.map { ($0.id, $0.name) })
                            }
                        }
                    }
                    if let dose = p?.dose, !dose.isEmpty {
                        Panel {
                            PanelLabel(text: "Dose as published")
                            DoseTable(dose: dose)
                            Text("Shown as the cited source states it. TOXCARD does not calculate doses.")
                                .font(.system(size: 12.5)).foregroundStyle(Palette.dim).padding(.top, 2)
                        }
                    }
                    if let pit = p?.pitfall, !pit.isEmpty {
                        Panel(leading: Palette.sig, background: Palette.sigSoft) {
                            Label("Pitfall", systemImage: "exclamationmark.octagon.fill")
                                .font(.system(size: 12.5, weight: .semibold)).textCase(.uppercase)
                                .foregroundStyle(Palette.sig)
                            Text(pit).font(.system(size: 16.5, weight: .medium)).foregroundStyle(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let src = p?.sources, !src.isEmpty {
                        Panel {
                            PanelLabel(text: "Sources")
                            ForEach(Array(src.enumerated()), id: \.offset) { i, s in
                                if i > 0 { Divider() }
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    if let ty = s.type {
                                        Text(ty).font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Palette.mut)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Palette.fill, in: RoundedRectangle(cornerRadius: 5))
                                    }
                                    Text(s.label).font(.system(size: 14)).foregroundStyle(Palette.ink)
                                }
                            }
                        }
                    }
                    PoisonCenterButton()
                    if let r = p?.lastReviewed {
                        Text("Card reviewed \(r) · reference only, for trained clinicians")
                            .font(.system(size: 12.5)).foregroundStyle(Palette.dim)
                            .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                    }
                }
                .padding(16)
            }
            .background(Palette.ground)
            .navigationTitle(t.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(item: shareText(t, p)) { Image(systemName: "square.and.arrow.up") }
                    Button {
                        store.toggleSaved(t.id)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: store.isSaved(t.id) ? "star.fill" : "star")
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

    private func hero(_ t: Toxin, _ p: Protocol_?, _ tier: String) -> some View {
        let availability = Availability(p)
        let badge: (Color, Color) = {
            switch availability {
            case .available: return (Palette.acc, Palette.accSoft)
            case .notObtainable, .investigational: return (Palette.amber, Palette.amberSoft)
            case .supportive: return (Palette.ink, Palette.fill)
            }
        }()
        return Panel(top: Palette.tier(tier)) {
            HStack(alignment: .top, spacing: 13) {
                TierTab(tier: tier, large: true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(t.name).font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(t.category).font(.system(size: 14.5)).foregroundStyle(Palette.mut)
                    HStack(spacing: 6) {
                        Pill(text: tier == "N" ? "Tier —" : "Tier \(tier)", fg: Palette.tier(tier), bg: Palette.fill)
                        Pill(text: availability.label, fg: badge.0, bg: badge.1)
                    }
                    if let aka = t.aka, !aka.isEmpty {
                        Text("Also: " + aka.joined(separator: ", "))
                            .font(.system(size: 13)).foregroundStyle(Palette.dim)
                    }
                }
            }
            .padding(.top, 6)
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

/// Dose lines as a table: "Label: value" puts the label in the left column; steps joined by → stack.
struct DoseTable: View {
    let dose: String
    var body: some View {
        let lines = dose.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                if i > 0 { Divider() }
                let (k, v) = split(line)
                HStack(alignment: .top, spacing: 12) {
                    if let k {
                        Text(k).font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.ink)
                            .frame(width: 92, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        let steps = v.components(separatedBy: "→").map { $0.trimmingCharacters(in: .whitespaces) }
                        ForEach(Array(steps.enumerated()), id: \.offset) { j, step in
                            Text((j > 0 ? "→ " : "") + step)
                                .font(.system(size: 14, design: .monospaced)).foregroundStyle(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .textSelection(.enabled)
                }
                .padding(.vertical, 9)
            }
        }
    }

    private func split(_ line: String) -> (String?, String) {
        if let r = line.range(of: ":") {
            let k = String(line[..<r.lowerBound])
            if k.count >= 2 && k.count <= 30 {
                return (k, String(line[r.upperBound...]).trimmingCharacters(in: .whitespaces))
            }
        }
        return (nil, line)
    }
}

/// Agent chips that wrap onto new lines.
struct FlowChips: View {
    let items: [(id: String, name: String)]
    var body: some View {
        WrapLayout(spacing: 7) {
            ForEach(items, id: \.id) { item in
                NavigationLink(value: Route.agent(item.id)) {
                    HStack(spacing: 3) {
                        Text(item.name)
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                    }
                    .font(.system(size: 15, weight: .medium))
                    .padding(.horizontal, 14).frame(minHeight: 36)
                    .foregroundStyle(Palette.acc)
                    .background(Palette.accSoft, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct WrapLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0 && x + sz.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
        return CGSize(width: maxW == .infinity ? x : maxW, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + sz.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}
