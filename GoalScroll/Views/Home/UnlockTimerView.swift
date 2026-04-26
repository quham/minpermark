import SwiftUI

struct UnlockTimerView: View {
    let availableMinutes: Int
    let onDismiss: () -> Void
    let onDeductMinutes: (Int) -> Void

    @State private var selectedMinutes: Int = 10
    @Environment(ScreenTimeManager.self) var screenTimeManager

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
        NavigationStack {
            ZStack {
                GradientBackgroundView()

                VStack(spacing: AppSpacing.lg) {
                    if isUnlocked {
                        unlockedView
                    } else {
                        selectionView
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle(isUnlocked ? "Apps Unlocked" : "Unlock Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Selection View

    private var selectionView: some View {
        VStack(spacing: AppSpacing.xl) {
            // Available minutes display
            VStack(spacing: AppSpacing.xs) {
                Text("\(availableMinutes)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primary)

                Text("minutes earned today")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            // Selection
            VStack(spacing: AppSpacing.md) {
                Text("Take a break for...")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                if minuteOptions.isEmpty {
                    Text("No minutes available yet.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
                } else {
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(minuteOptions, id: \.self) { minutes in
                            Text("\(minutes) min")
                                .tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .environment(\.colorScheme, .light)
                    .frame(height: 140)
                }
            }
            .onAppear {
                if let firstOption = minuteOptions.first, !minuteOptions.contains(selectedMinutes) {
                    selectedMinutes = firstOption
                }
            }

            Spacer()

            // Unlock button
            PrimaryButton(
                title: "Unlock for \(selectedMinutes) min",
                isEnabled: availableMinutes >= selectedMinutes
            ) {
                startUnlock()
            }

            // Info text
            Text("Your apps will be available while the timer runs")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Unlocked View

    private var unlockedView: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
            let remaining = timeRemaining(at: timeline.date)
            let progress = progressValue(remaining: remaining)
            
            VStack(spacing: AppSpacing.xl) {
                // Timer display
                ZStack {
                    Circle()
                        .stroke(AppColors.inputBackground, lineWidth: 8)
                        .frame(width: 200, height: 200)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AppColors.primary,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    VStack(spacing: AppSpacing.xxs) {
                        Text(timeString(remaining: remaining))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)

                        Text("remaining")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                // Status message
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.success)

                    Text("Apps are unlocked")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Enjoy your break!")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                // End early button
                SecondaryButton(title: "End early") {
                    let minutesUsed = screenTimeManager.endUnlockSession()
                    AnalyticsService.shared.capture(Constants.AnalyticsEvents.unlockEnded, properties: [
                        Constants.AnalyticsProperties.minutesUsed: minutesUsed,
                        Constants.AnalyticsProperties.endedEarly: true
                    ])
                    onDeductMinutes(minutesUsed)
                }
            }
            .onChange(of: remaining) { _, newValue in
                if newValue <= 0 {
                    AnalyticsService.shared.capture(Constants.AnalyticsEvents.unlockEnded, properties: [
                        Constants.AnalyticsProperties.minutesUsed: selectedMinutes,
                        Constants.AnalyticsProperties.endedEarly: false
                    ])
                    // Break ended naturally - deduction is handled by DeviceActivityMonitor
                    // and processed on next app launch via HomeView
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
        // We don't have the original duration here easily without another @State
        // But we can estimate it or just use the last selectedMinutes
        let totalSeconds = Double(selectedMinutes * 60)
        return min(max(remaining / totalSeconds, 0), 1)
    }

    private func timeString(remaining: TimeInterval) -> String {
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startUnlock() {
        guard screenTimeManager.hasSelection else {
            HapticManager.notification(.error)
            return
        }

        // Haptic feedback for successful unlock
        HapticManager.notification(.success)

        screenTimeManager.startUnlockSession(for: selectedMinutes)
        AnalyticsService.shared.capture(Constants.AnalyticsEvents.unlockStarted, properties: [
            Constants.AnalyticsProperties.minutesRequested: selectedMinutes,
            "minutes_available": availableMinutes
        ])
    }
}

struct MinuteOptionButton: View {
    let minutes: Int
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text("\(minutes)")
                .font(AppTypography.headline)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(isSelected ? AppColors.primary : Color.white)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? AppColors.primary : AppColors.inputBorder,
                            lineWidth: isSelected ? 0 : 1
                        )
                )
                .shadow(
                    color: isSelected ? AppColors.primary.opacity(0.3) : AppColors.shadowColor,
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: 2
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    UnlockTimerView(availableMinutes: 32, onDismiss: {}, onDeductMinutes: { _ in })
        .environment(ScreenTimeManager.shared)
}
