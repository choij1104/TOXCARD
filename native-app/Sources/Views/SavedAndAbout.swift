import SwiftUI

struct SavedView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            Section {
                ForEach(store.saved, id: \.self) { id in
                    if let t = store.toxin(id) {
                        NavigationLink(value: Route.toxin(id)) { ToxinRow(toxin: t) }
                    }
                }
                .onDelete { store.removeSaved(at: $0) }
            } header: {
                Text("Saved cards")
            } footer: {
                Text("Saved on this iPhone only. Touch and hold the TOXCARD icon to open your first two saved cards.")
            }
            if !store.recent.isEmpty {
                Section {
                    ForEach(store.recent, id: \.self) { id in
                        if let t = store.toxin(id) {
                            NavigationLink(value: Route.toxin(id)) { ToxinRow(toxin: t) }
                        }
                    }
                } header: {
                    HStack {
                        Text("Recently viewed")
                        Spacer()
                        Button("Clear") { store.clearRecent() }.font(.caption)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Palette.ground)
        .navigationTitle("Saved")
        .overlay {
            if store.saved.isEmpty && store.recent.isEmpty {
                ContentUnavailableView("No saved cards",
                                       systemImage: "bookmark",
                                       description: Text("Tap the bookmark on any toxin card to keep it here."))
            }
        }
        .toolbar { if !store.saved.isEmpty { EditButton() } }
    }
}

struct AboutView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("TOXCARD is a toxicology reference for trained clinicians: toxin, agent, dose as published, and the pitfall, on one screen.")
                    Text("It is not a substitute for clinical judgment or a regional poison center. In the United States call 1-800-222-1222.")
                        .foregroundStyle(Palette.sig)
                    PoisonCenterButton().listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                }
                Section("Dataset") {
                    LabeledContent("Toxins", value: "\(store.toxins.count)")
                    LabeledContent("Antidote agents", value: "\(store.agents.count)")
                    LabeledContent("Toxidromes", value: "\(store.toxidromes.count)")
                    if let v = store.version {
                        LabeledContent("Version", value: v.version)
                        if let r = v.lastReviewed { LabeledContent("Last reviewed", value: r) }
                        if let n = v.nextReviewDue { LabeledContent("Next review due", value: n) }
                    }
                }
                Section {
                    Text("Doses are shown exactly as their cited sources state them. TOXCARD performs no dose calculation. Each card lists its sources: FDA prescribing information, guidelines, consensus statements and standard textbooks.")
                        .font(.footnote)
                } header: { Text("Sources") }
                Section("Privacy") {
                    Text("No account, no sign-in, no network. Saved cards and recent views stay on this iPhone. TOXCARD collects no data.")
                        .font(.footnote)
                    Link("Privacy policy", destination: URL(string: "https://choij1104.github.io/TOXCARD/privacy.html")!)
                }
                Section {
                    LabeledContent("Publisher", value: "HAKOYA LLC")
                    LabeledContent("App version",
                                   value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                    Link("Contact", destination: URL(string: "mailto:admin@hakoyallc.com")!)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

/// Shown once on first launch.
struct NoticeView: View {
    let onAccept: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            (Text("TOX").foregroundStyle(Palette.ink) + Text("CARD").foregroundStyle(Palette.acc))
                .font(.system(size: 36, weight: .heavy)).tracking(2)
            ECGLine().stroke(Palette.sig, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round)).frame(height: 24)
            Text("A bedside toxicology reference for trained clinicians.")
                .font(.title3)
            VStack(alignment: .leading, spacing: 10) {
                Label("Doses are shown as their sources publish them. Nothing is calculated.", systemImage: "doc.text")
                Label("Works fully offline. No account, no data collected.", systemImage: "wifi.slash")
                Label("Not a substitute for a poison center: 1-800-222-1222.", systemImage: "phone")
            }
            .font(.callout)
            Spacer()
            Button(action: onAccept) {
                Text("I understand").font(.headline).frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.acc)
        }
        .padding(28)
        .background(Palette.ground)
        .interactiveDismissDisabled()
    }
}
