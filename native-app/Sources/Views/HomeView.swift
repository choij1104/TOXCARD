import SwiftUI

/// Time-critical entries and their one-line reminders, as written for the TOXCARD 1.1 home screen.
let urgentEntries: [(id: String, line: String)] = [
    ("039-cyanide-smoke-inhalation-hcn-nitroprusside-acetonitrile-apri", "Hydroxocobalamin on suspicion · smoke inhalation"),
    ("047-nerve-agents-sarin-soman-tabun-vx-novichok-class", "Oxime before aging · minutes for soman"),
    ("button-battery-ingestion", "Endoscopic removal within 2 h · no antidote"),
    ("001-acetaminophen-paracetamol", "NAC within 8 h for full hepatoprotection"),
    ("041-carbon-monoxide", "HBO benefit greatest within 6 h"),
]

struct HomeView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var router: Router
    @State private var showAbout = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                urgentStrip
                findSection
                if !store.saved.isEmpty { savedSection }
                PoisonCenterButton().padding(.horizontal, 16)
                footer
            }
            .padding(.bottom, 24)
        }
        .background(Palette.ground)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAbout) { AboutView() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                (Text("TOX").foregroundStyle(Palette.ink) + Text("CARD").foregroundStyle(Palette.acc))
                    .font(.system(size: 30, weight: .heavy)).tracking(2)
                Spacer()
                Button { showAbout = true } label: {
                    Image(systemName: "info.circle").font(.system(size: 20)).foregroundStyle(Palette.mut)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("About TOXCARD")
            }
            ECGLine().stroke(Palette.sig, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
                .frame(height: 22)
            Text("Toxin · Agent · Pitfall").font(.system(size: 13, weight: .medium)).tracking(1.5)
                .foregroundStyle(Palette.mut)
            Button {
                router.query = ""
                router.tab = .toxins
                router.toxinPath = []
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Toxin, drug, brand or antidote")
                    Spacer()
                }
                .font(.system(size: 16))
                .foregroundStyle(Palette.dim)
                .padding(.horizontal, 12).frame(height: 44)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .accessibilityLabel("Search toxins")
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    private var urgentStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Time-critical", count: urgentEntries.count)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(urgentEntries, id: \.id) { u in
                        if let t = store.toxin(u.id) {
                            NavigationLink(value: Route.toxin(t.id)) { UrgentCard(title: t.name, line: u.line) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var findSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Three ways to find")
            VStack(spacing: 0) {
                findRow(icon: "allergens", tint: Palette.acc, soft: Palette.accSoft,
                        title: "By toxin", sub: "\(store.toxins.count) cards in \(store.categories.count) categories") {
                    router.tab = .toxins; router.toxinPath = []
                }
                Divider().padding(.leading, 58)
                findRow(icon: "eye", tint: Palette.amber, soft: Palette.amberSoft,
                        title: "By what you see", sub: "\(store.toxidromes.count) toxidromes, side by side") {
                    router.tab = .signs; router.signsPath = []
                }
                Divider().padding(.leading, 58)
                findRow(icon: "syringe", tint: Palette.sig, soft: Palette.sigSoft,
                        title: "By antidote", sub: "\(store.agents.count) agents and the toxins each treats") {
                    router.tab = .antidotes; router.antidotePath = []
                }
            }
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Saved", count: store.saved.count)
            VStack(spacing: 0) {
                ForEach(Array(store.saved.prefix(4).enumerated()), id: \.element) { i, id in
                    if let t = store.toxin(id) {
                        if i > 0 { Divider().padding(.leading, 58) }
                        NavigationLink(value: Route.toxin(id)) {
                            HStack { ToxinRow(toxin: t); Spacer(); chevron }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    private var footer: some View {
        Text("Dataset \(store.version?.version ?? "") · reviewed \(store.version?.lastReviewed ?? "") · works offline")
            .font(.system(size: 12.5)).foregroundStyle(Palette.dim)
            .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 4)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.dim)
    }

    private func sectionTitle(_ s: String, count: Int? = nil) -> some View {
        HStack(spacing: 6) {
            Text(s).font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.ink)
            if let c = count { Text("\(c)").font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.dim) }
        }
        .padding(.horizontal, 16)
    }

    private func findRow(icon: String, tint: Color, soft: Color, title: String, sub: String,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(tint)
                    .frame(width: 32, height: 32).background(soft, in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 16.5, weight: .medium)).foregroundStyle(Palette.ink)
                    Text(sub).font(.system(size: 13.5)).foregroundStyle(Palette.mut)
                }
                Spacer()
                chevron
            }
            .padding(.horizontal, 14).frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
