import SwiftUI

struct DailyCapView: View {
    @Bindable var profile: UserProfile
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Daily unlock cap").font(.mathTitle)
            GlassCard {
                VStack(spacing: 12) {
                    Text("\(profile.dailyCapMinutes) min").font(.mathDisplay)
                    Slider(value: Binding(
                        get: { Double(profile.dailyCapMinutes) },
                        set: { profile.dailyCapMinutes = Int($0) }
                    ), in: 30...240, step: 15)
                    Text("Max minutes per day you can earn for unlocking apps.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Button("Continue") { onNext() }
                .buttonStyle(.borderedProminent)
        }.padding()
    }
}
