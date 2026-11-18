import SwiftUI

enum Palette {
    static func tier(_ t: String) -> Color {
        switch t {
        case "A": return Color(red: 0.13, green: 0.55, blue: 0.42)
        case "B": return Color(red: 0.16, green: 0.45, blue: 0.70)
        case "C": return Color(red: 0.62, green: 0.45, blue: 0.10)
        case "D": return Color(red: 0.70, green: 0.33, blue: 0.10)
        default:  return Color.gray
        }
    }
    static let pitfall = Color(red: 0.78, green: 0.17, blue: 0.20)
}

struct RootView: View {
    @EnvironmentObject var router: Router

    var body: some View {
        TabView(selection: $router.tab) {
            NavigationStack(path: $router.toxinPath) {
                ToxinListView()
                    .navigationDestination(for: Route.self) { RouteView(route: $0) }
            }
            .tabItem { Label("Toxins", systemImage: "flask") }
            .tag(Tab.toxins)

            NavigationStack(path: $router.signsPath) {
                SignsView()
                    .navigationDestination(for: Route.self) { RouteView(route: $0) }
            }
            .tabItem { Label("Signs", systemImage: "eye") }
            .tag(Tab.signs)

            NavigationStack(path: $router.antidotePath) {
                AgentListView()
                    .navigationDestination(for: Route.self) { RouteView(route: $0) }
            }
            .tabItem { Label("Antidotes", systemImage: "cross.vial") }
            .tag(Tab.antidotes)

            NavigationStack(path: $router.savedPath) {
                SavedView()
                    .navigationDestination(for: Route.self) { RouteView(route: $0) }
            }
            .tabItem { Label("Saved", systemImage: "bookmark") }
            .tag(Tab.saved)
        }
    }
}

struct RouteView: View {
    let route: Route
    var body: some View {
        switch route {
        case .toxin(let id): ToxinCardView(toxinId: id)
        case .agent(let id): AgentDetailView(agentId: id)
        case .toxidrome(let id): ToxidromeDetailView(toxidromeId: id)
        }
    }
}

/// The tier badge used in every list row: the letter on a coloured tab, "–" for supportive care.
struct TierBadge: View {
    let tier: String
    var body: some View {
        Text(tier == "N" ? "–" : tier)
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(Palette.tier(tier), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .accessibilityLabel(tier == "N" ? "Supportive care" : "Tier \(tier)")
    }
}

struct ToxinRow: View {
    @EnvironmentObject var store: Store
    let toxin: Toxin
    var body: some View {
        let p = store.protocolFor(toxin.id)
        HStack(spacing: 12) {
            TierBadge(tier: p?.tier ?? "N")
            VStack(alignment: .leading, spacing: 2) {
                Text(toxin.name).font(.body.weight(.semibold)).foregroundStyle(.primary)
                Text(p?.agentLine ?? toxin.category)
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

struct PoisonCenterButton: View {
    var body: some View {
        Link(destination: URL(string: "tel://18002221222")!) {
            Label("Call Poison Control  1-800-222-1222", systemImage: "phone.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(Palette.pitfall)
    }
}
