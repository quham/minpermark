import SwiftUI

struct SettingsView: View {
    @Bindable var profile: UserProfile
    @Environment(PaywallStore.self) private var paywall
    @Environment(\.modelContext) private var context

    var body: some View {
        Form {
            Section("Exam") {
                Picker("Level", selection: $profile.level) {
                    ForEach(ExamLevel.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
                }
                Picker("Board", selection: $profile.board) {
                    ForEach(ExamBoard.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
                }
                if profile.level == .gcse {
                    Picker("Tier", selection: Binding(
                        get: { profile.tier ?? .higher },
                        set: { profile.tier = $0 }
                    )) {
                        ForEach(Tier.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }
                }
            }
            Section("Limits") {
                Stepper("Daily cap: \(profile.dailyCapMinutes) min",
                        value: $profile.dailyCapMinutes, in: 30...240, step: 15)
            }
            Section("Subscription") {
                if let e = profile.entitlement, e.isActive {
                    Text("Active: \(e.productId)")
                    Text("Renews \(e.expiresAt.formatted())").foregroundStyle(.secondary)
                } else {
                    Text("No active subscription")
                }
                Button("Restore purchases") { Task { await paywall.restore() } }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .onChange(of: profile.dailyCapMinutes) { try? context.save() }
        .onChange(of: profile.level) { try? context.save() }
        .onChange(of: profile.board) { try? context.save() }
    }
}
