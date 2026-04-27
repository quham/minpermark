import SwiftUI

struct UnlockTimerView: View {
    @Environment(MinutesStore.self) private var minutes
    @Environment(ScreenTimeManager.self) var screenTimeManager

    @State private var selectedMinutes: Int = 10

    private var availableMinutes: Int { minutes.balance }

    private var isUnlocked: Bool {
        if let expiry = screenTimeManager.unlockExpiryDate {
            return expiry > Date()
        }
        return false
    }

    private var minuteOptions: [Int] {
        let maxMinutes = min(availableMinutes, 20)
        return maxMinutes > 0 ? Array(1...maxMinutes) : []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.padLarge) {
                if isUnlocked {
                    unlockedView
                } else {
                    selectionView
                }
            }
            .padding()
        }
        .navigationTitle(isUnlocked ? "Apps Unlocked" : "Unlock Apps")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Selection View

    private var selectionView: some View {
        VStack(spacing: Theme.padLarge) {
            GlassCard {
                VStack(spacing: 8) {
                    Text("\(availableMinutes)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accent)

                    Text("minutes earned today")
                        .font(.mathBody)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            GlassCard {
                VStack(spacing: Theme.pad) {
                    Text("Take a break for…")
                        .font(.mathBody.weight(.semibold))

                    if minuteOptions.isEmpty {
                        Text("No minutes available yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(minuteOptions, id: \.self) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 140)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .onAppear {
                if let first = minuteOptions.first, !minuteOptions.contains(selectedMinutes) {
                    selectedMinutes = first
                }
            }

            Button("Unlock for \(selectedMinutes) min") {
                startUnlock()
            }
            .buttonStyle(.borderedProminent)
            .disabled(minuteOptions.isEmpty || availableMinutes < selectedMinutes)

            Text("Your apps will be available while the timer runs")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Unlocked View

    private var unlockedView: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
            let remaining = timeRemaining(at: timeline.date)
            let progress = progressValue(remaining: remaining)

            VStack(spacing: Theme.padLarge) {
                GlassCard {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                            .frame(width: 200, height: 200)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                Theme.accent,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: progress)

                        VStack(spacing: 4) {
                            Text(timeString(remaining: remaining))
                                .font(.system(size: 48, weight: .bold, design: .rounded))

                            Text("remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.pad)
                }

                GlassCard {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.success)

                        Text("Apps are unlocked")
                            .font(.mathBody.weight(.semibold))

                        Text("Enjoy your break!")
                            .font(.mathBody)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                Button("End early") {
                    let minutesUsed = screenTimeManager.endUnlockSession()
                    minutes.spend(minutes: minutesUsed)
                    AnalyticsService.shared.capture(
                        Constants.AnalyticsEvents.unlockEnded,
                        properties: [
                            Constants.AnalyticsProperties.minutesUsed: minutesUsed,
                            Constants.AnalyticsProperties.endedEarly: true
                        ]
                    )
                }
                .buttonStyle(.bordered)
            }
            .onChange(of: remaining) { _, newValue in
                if newValue <= 0 {
                    AnalyticsService.shared.capture(
                        Constants.AnalyticsEvents.unlockEnded,
                        properties: [
                            Constants.AnalyticsProperties.minutesUsed: selectedMinutes,
                            Constants.AnalyticsProperties.endedEarly: false
                        ]
                    )
                    screenTimeManager.enableBlocking()
                }
            }
        }
    }

    // MARK: - Helpers

    private func timeRemaining(at date: Date) -> TimeInterval {
        guard let expiry = screenTimeManager.unlockExpiryDate else { return 0 }
        return max(expiry.timeIntervalSince(date), 0)
    }

    private func progressValue(remaining: TimeInterval) -> Double {
        let totalSeconds = Double(selectedMinutes * 60)
        return min(max(remaining / totalSeconds, 0), 1)
    }

    private func timeString(remaining: TimeInterval) -> String {
        let m = Int(remaining) / 60
        let s = Int(remaining) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func startUnlock() {
        guard screenTimeManager.hasSelection else {
            HapticManager.notification(.error)
            return
        }
        HapticManager.notification(.success)
        screenTimeManager.startUnlockSession(for: selectedMinutes)
        AnalyticsService.shared.capture(
            Constants.AnalyticsEvents.unlockStarted,
            properties: [
                Constants.AnalyticsProperties.minutesRequested: selectedMinutes,
                "minutes_available": availableMinutes
            ]
        )
    }
}
