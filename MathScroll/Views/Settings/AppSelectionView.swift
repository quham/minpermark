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
            ScrollView {
                VStack(spacing: Theme.padLarge) {
                    // Header explanation
                    VStack(spacing: Theme.pad) {
                        Image(systemName: "hourglass.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(Theme.accent)

                        Text("Choose Apps to Block")
                            .font(.mathTitle)

                        Text("Select apps and categories that distract you. They'll be blocked until you earn unlock time.")
                            .font(.mathBody)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.padLarge)
                    .padding(.horizontal, Theme.padLarge)

                    // Current selection summary
                    if screenTimeManager.hasSelection {
                        SelectionSummaryCard(
                            appCount: screenTimeManager.selectedAppCount,
                            categoryCount: screenTimeManager.selectedCategoryCount
                        )
                        .padding(.horizontal, Theme.padLarge)
                    }

                    // Select apps button
                    Button(action: { isPickerPresented = true }) {
                        HStack {
                            Image(systemName: "apps.iphone")
                                .font(.system(size: 20))
                            Text(screenTimeManager.hasSelection ? "Change Selection" : "Select Apps & Categories")
                                .font(.mathBody.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Theme.accent)
                        .padding(Theme.pad)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.cornerMedium)
                                .fill(Theme.accent.opacity(0.1))
                        )
                    }
                    .padding(.horizontal, Theme.padLarge)

                    // Blocking status
                    if screenTimeManager.hasSelection {
                        BlockingStatusCard(
                            isBlocking: screenTimeManager.isBlocking,
                            unlockExpiryDate: screenTimeManager.unlockExpiryDate
                        )
                        .padding(.horizontal, Theme.padLarge)
                    }

                    // Info cards
                    VStack(spacing: Theme.pad) {
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
                    .padding(.horizontal, Theme.padLarge)

                    // Clear selection button
                    if screenTimeManager.hasSelection {
                        Button(action: { screenTimeManager.clearSelection() }) {
                            Text("Clear Selection")
                                .font(.mathBody)
                                .foregroundColor(.red)
                        }
                        .padding(.top, Theme.pad)
                    }

                    Spacer().frame(height: Theme.padLarge * 2)
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
        HStack(spacing: Theme.padLarge) {
            VStack(spacing: 4) {
                Text("\(appCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accent)
                Text("Apps")
                    .font(.mathBody)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(categoryCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accent)
                Text("Categories")
                    .font(.mathBody)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Theme.pad)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerMedium)
                .fill(Color(uiColor: .systemBackground))
                .shadow(radius: 4, y: 2)
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
        if isBlocking { return "Blocking Active" }
        if isUnlockActive { return "Blocking Paused" }
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
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isBlocking ? Theme.success : Color.secondary)
                        .frame(width: 8, height: 8)
                    Text(statusTitle)
                        .font(.mathBody.weight(.semibold))
                }

                statusDescription
                    .font(.mathBody)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(Theme.pad)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerMedium)
                .fill(Color(uiColor: .systemBackground))
                .shadow(radius: 4, y: 2)
        )
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.pad) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.mathBody.weight(.semibold))

                Text(description)
                    .font(.mathBody)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Theme.pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerMedium)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

#else

// MARK: - Fallback View (FamilyControls not available)

struct AppSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.padLarge) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 56))
                    .foregroundColor(Theme.warning)

                Text("Screen Time Not Available")
                    .font(.mathTitle)

                Text("App blocking requires Screen Time capabilities which are not available on this device or simulator.")
                    .font(.mathBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.padLarge * 2)

                Text("The app will use reminders and timers instead.")
                    .font(.mathBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.padLarge * 2)
            }
            .padding()
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
