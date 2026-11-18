import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: Router

    var body: some View {
        TabView(selection: $router.tab) {
            NavigationStack(path: $router.homePath) {
                HomeView().navigationDestination(for: Route.self) { RouteView(route: $0) }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(Tab.home)

            NavigationStack(path: $router.toxinPath) {
                ToxinListView().navigationDestination(for: Route.self) { RouteView(route: $0) }
            }
            .tabItem { Label("Toxins", systemImage: "allergens") }
            .tag(Tab.toxins)

            NavigationStack(path: $router.signsPath) {
                SignsView().navigationDestination(for: Route.self) { RouteView(route: $0) }
            }
            .tabItem { Label("Signs", systemImage: "eye") }
            .tag(Tab.signs)

            NavigationStack(path: $router.antidotePath) {
                AgentListView().navigationDestination(for: Route.self) { RouteView(route: $0) }
            }
            .tabItem { Label("Antidotes", systemImage: "syringe") }
            .tag(Tab.antidotes)

            NavigationStack(path: $router.savedPath) {
                SavedView().navigationDestination(for: Route.self) { RouteView(route: $0) }
            }
            .tabItem { Label("Saved", systemImage: "bookmark") }
            .tag(Tab.saved)
        }
        .tint(Palette.acc)
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

/// A list row in the 1.1 style: index-card tab, name, agent line.
struct ToxinRow: View {
    @EnvironmentObject var store: Store
    let toxin: Toxin
    var body: some View {
        let p = store.protocolFor(toxin.id)
        HStack(spacing: 12) {
            TierTab(tier: p?.tier ?? "N")
            VStack(alignment: .leading, spacing: 1) {
                Text(toxin.name).font(.system(size: 16.5, weight: .medium)).foregroundStyle(Palette.ink)
                Text(p?.agentLine ?? toxin.category)
                    .font(.system(size: 13.5)).foregroundStyle(Palette.mut).lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

/// The time-critical strip (1.1 design): cards with a red top edge.
struct UrgentCard: View {
    let title: String
    let line: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Time-critical", systemImage: "clock")
                .font(.system(size: 12, weight: .semibold)).textCase(.uppercase)
                .foregroundStyle(Palette.sig)
            Text(title).font(.system(size: 19, weight: .bold)).foregroundStyle(Palette.ink)
                .lineLimit(2).multilineTextAlignment(.leading)
            Text(line).font(.system(size: 14)).foregroundStyle(Palette.mut)
                .lineLimit(2).multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.top, 13).padding(.bottom, 14)
        .frame(width: 250, height: 128, alignment: .topLeading)
        .background(Palette.surface)
        .overlay(alignment: .top) { Rectangle().fill(Palette.sig).frame(height: 4) }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
