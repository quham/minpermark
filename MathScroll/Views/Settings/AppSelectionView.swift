import SwiftUI

#if canImport(FamilyControls)
import FamilyControls

// MARK: - App Selection View

struct AppSelectionView: View {
    @Environment(ScreenTimeManager.self) var screenTimeManager
    @Environment(\.dismiss) private var dismiss

    @State private var isPickerPresented = false

    var body: some View {
        @Bindable var screenTimeManager = screenTimeManager
        NavigationStack {
            ZStack {
                GradientBackgroundView()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Header explanation
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: "hourglass.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(AppColors.primary)

                            Text("Choose Apps to Block")
                                .font(AppTypography.title)
                                .foregroundColor(AppColors.textPrimary)

                            Text("Select apps and categories that distract you. They'll be blocked until you earn unlock time.")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, AppSpacing.xl)
                        .padding(.horizontal, AppSpacing.lg)

                        // Current selection summary
                        if screenTimeManager.hasSelection {
                            SelectionSummaryCard(
                                appCount: screenTimeManager.selectedAppCount,
                                categoryCount: screenTimeManager.selectedCategoryCount
                            )
                            .padding(.horizontal, AppSpacing.lg)
                        }

                        // Select apps button
                        Button(action: { isPickerPresented = true }) {
                            HStack {
                                Image(systemName: "apps.iphone")
                                    .font(.system(size: 20))
                                Text(screenTimeManager.hasSelection ? "Change Selection" : "Select Apps & Categories")
                                    .font(AppTypography.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(AppColors.primary)
                            .padding(AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .fill(AppColors.primary.opacity(0.1))
                            )
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        // Blocking status
                        if screenTimeManager.hasSelection {
                            BlockingStatusCard(
                                isBlocking: screenTimeManager.isBlocking,
                                unlockExpiryDate: screenTimeManager.unlockExpiryDate
                            )
                            .padding(.horizontal, AppSpacing.lg)
                        }

                        // Info cards
                        VStack(spacing: AppSpacing.md) {
                            InfoCard(
                                icon: "lock.shield",
                                title: "How it works",
                                description: "Selected apps will be blocked. Complete your habits to earn minutes, then use those minutes to unlock apps temporarily."
                            )

                            InfoCard(
                                icon: "hand.raised",
                                title: "Stay in control",
                                description: "Change your selection any time. Unlocking only happens from Home with earned minutes."
                            )
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        // Clear selection button
                        if screenTimeManager.hasSelection {
                            Button(action: { screenTimeManager.clearSelection() }) {
                                Text("Clear Selection")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.error)
                            }
                            .padding(.top, AppSpacing.md)
                        }

                        Spacer().frame(height: AppSpacing.xxl)
                    }
                }
            }
            .navigationTitle("App Blocking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $screenTimeManager.selectedApps
            )
            .task {
                if !screenTimeManager.isAuthorized {
                    _ = await screenTimeManager.requestAuthorization()
                }
            }
        }
    }
}

// MARK: - Selection Summary Card

struct SelectionSummaryCard: View {
    let appCount: Int
    let categoryCount: Int

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xxs) {
                Text("\(appCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primary)
                Text("Apps")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: AppSpacing.xxs) {
                Text("\(categoryCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primary)
                Text("Categories")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(Color.white)
                .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Blocking Status Card

struct BlockingStatusCard: View {
    let isBlocking: Bool
    let unlockExpiryDate: Date?

    private var isUnlockActive: Bool {
        if let expiry = unlockExpiryDate { return expiry > Date() }
        return false
    }

    private var statusTitle: String {
        if isBlocking {
            return "Blocking Active"
        }
        if isUnlockActive {
            return "Blocking Paused"
        }
        return "Blocking Off"
    }

    private var statusDescription: Text {
        if isBlocking {
            return Text("Selected apps are blocked. Unlock from Home with earned minutes.")
        }
        if isUnlockActive {
            if let expiryDate = unlockExpiryDate {
                return Text("Unlock ends at ") + Text(expiryDate, style: .time)
            }
            return Text("Unlock in progress")
        }
        return Text("Blocking is not active right now.")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xs) {
                    Circle()
                        .fill(isBlocking ? AppColors.success : AppColors.textMuted)
                        .frame(width: 8, height: 8)
                    Text(statusTitle)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                }

                statusDescription
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(Color.white)
                .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppTypography.subheadline.weight(.medium))
                    .foregroundColor(AppColors.textPrimary)

                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.inputBackground)
        )
    }
}

#else

// MARK: - Fallback View (FamilyControls not available)

struct AppSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackgroundView()

                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 56))
                        .foregroundColor(AppColors.warning)

                    Text("Screen Time Not Available")
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)

                    Text("App blocking requires Screen Time capabilities which are not available on this device or simulator.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)

                    Text("The app will use reminders and timers instead.")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
                .padding()
            }
            .navigationTitle("App Blocking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#endif

// MARK: - Previews

#Preview("App Selection") {
    AppSelectionView()
        .environment(ScreenTimeManager.shared)
}
