import SwiftUI
import SwiftData

#if canImport(FamilyControls)
import FamilyControls
#endif

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) var appState

    @Query private var stats: [UserStats]
    @State private var showingAppSelection = false
    @State private var showingDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountError: String? = nil
    @AppStorage(Constants.UserDefaultsKeys.notificationSoundEnabled) private var notificationSoundEnabled = true
    @AppStorage(Constants.UserDefaultsKeys.saveHabitLogs) private var saveHabitLogs = true
    @AppStorage(Constants.UserDefaultsKeys.weeklyReviewDay) private var weeklyReviewDay = 1 // Sunday
    @AppStorage(Constants.UserDefaultsKeys.weeklyReviewTime) private var weeklyReviewTime: Double = 19 * 3600 // 7 PM

    @Environment(ScreenTimeManager.self) var screenTimeManager
    @Environment(NotificationManager.self) var notificationManager

    private var userStats: UserStats? {
        stats.first
    }

    private var notificationsEnabledBinding: Binding<Bool> {
        Binding(
            get: { notificationManager.isAuthorized },
            set: { newValue in
                if newValue {
                    if notificationManager.isDenied {
                        notificationManager.openSettings()
                    } else {
                        Task {
                            let granted = await notificationManager.requestAuthorization()
                            if granted {
                                notificationManager.setupNotificationCategories()
                            }
                        }
                    }
                } else {
                    notificationManager.openSettings()
                }
            }
        )
    }

    private var weeklyReviewTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: Int(weeklyReviewTime) / 3600,
                                     minute: (Int(weeklyReviewTime) % 3600) / 60,
                                     second: 0,
                                     of: Date()) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                weeklyReviewTime = Double((components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60)
                NotificationManager.shared.scheduleWeeklyReviewNotification()
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackgroundView()

                List {
                    // Account section
                    Section {
                        // User info row
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.primary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.displayName.isEmpty ? "User" : appState.displayName)
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.textPrimary)

                                if let email = appState.userEmail {
                                    Text(email)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }

                            Spacer()

                            // Sync status indicator
                            VStack(alignment: .trailing, spacing: 2) {
                                if appState.isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else if appState.lastSyncDate != nil {
                                    Image(systemName: "checkmark.icloud.fill")
                                        .foregroundColor(AppColors.success)
                                } else {
                                    Image(systemName: "icloud.slash")
                                        .foregroundColor(AppColors.textMuted)
                                }

                                if let lastSync = appState.lastSyncDate {
                                    Text(lastSync, style: .relative)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textMuted)
                                }
                            }
                        }

                        // Manual sync button
                        Button {
                            Task {
                                await SyncManager.shared.performFullSync(modelContext: modelContext)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(AppColors.primary)
                                Text("Sync Now")
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                if case .failed(let message) = appState.syncStatus {
                                    Text(message)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.error)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .disabled(appState.isSyncing)

                        // Sign out button
                        Button(role: .destructive) {
                            Task {
                                await appState.signOut(modelContext: modelContext)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                        }
                    } header: {
                        Text("Account")
                    }

                    // App Blocking section
                    Section {
                        Button(action: { showingAppSelection = true }) {
                            HStack(spacing: AppSpacing.md) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: 16))
                                    .foregroundColor(.purple)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Blocked Apps")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textPrimary)

                                    if screenTimeManager.hasSelection {
                                        Text("\(screenTimeManager.selectedAppCount) apps, \(screenTimeManager.selectedCategoryCount) categories")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    } else {
                                        Text("No apps selected")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textMuted)
                                    }
                                }

                                Spacer()

                                if screenTimeManager.isBlocking {
                                    Text("Active")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(AppColors.success))
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textMuted)
                            }
                        }

                    } header: {
                        Text("App Blocking")
                    } footer: {
                        Text("Select apps to block. Complete habits to earn unlock time.")
                    }

                    // Weekly Review Section
                    Section {
                        Picker(selection: $weeklyReviewDay) {
                            Text("Sunday").tag(1)
                            Text("Monday").tag(2)
                            Text("Tuesday").tag(3)
                            Text("Wednesday").tag(4)
                            Text("Thursday").tag(5)
                            Text("Friday").tag(6)
                            Text("Saturday").tag(7)
                        } label: {
                            SettingsRow(
                                icon: "calendar",
                                iconColor: .blue,
                                title: "Review day",
                                value: ""
                            )
                        }
                        .onChange(of: weeklyReviewDay) { _, _ in
                            NotificationManager.shared.scheduleWeeklyReviewNotification()
                        }

                        DatePicker(selection: weeklyReviewTimeBinding, displayedComponents: .hourAndMinute) {
                            SettingsRow(
                                icon: "clock",
                                iconColor: .blue,
                                title: "Review time",
                                value: ""
                            )
                        }
                    } header: {
                        Text("Weekly Review")
                    } footer: {
                        Text("Schedule when you want to review your progress each week.")
                    }

                    // Stats section
                    Section {
                        SettingsRow(
                            icon: "flame.fill",
                            iconColor: .orange,
                            title: "Current streak",
                            value: "\(userStats?.currentStreakDays ?? 0) days"
                        )

                        SettingsRow(
                            icon: "trophy.fill",
                            iconColor: .yellow,
                            title: "Longest streak",
                            value: "\(userStats?.longestStreakDays ?? 0) days"
                        )

                        SettingsRow(
                            icon: "clock.fill",
                            iconColor: AppColors.primary,
                            title: "Lifetime minutes",
                            value: "\(userStats?.lifetimeMinutesEarned ?? 0)"
                        )
                    } header: {
                        Text("Statistics")
                    }

                    // Preferences section
                    Section {
                        Toggle(isOn: notificationsEnabledBinding) {
                            SettingsRow(
                                icon: "bell.fill",
                                iconColor: AppColors.primary,
                                title: "Notifications",
                                value: notificationManager.isAuthorized ? "Enabled" : "Disabled"
                            )
                        }

                        if notificationManager.isAuthorized {
                            Toggle(isOn: $notificationSoundEnabled) {
                                SettingsRow(
                                    icon: "speaker.wave.2.fill",
                                    iconColor: AppColors.primary,
                                    title: "Notification sound",
                                    value: ""
                                )
                            }
                        }

                        Toggle(isOn: $saveHabitLogs) {
                            SettingsRow(
                                icon: "doc.text.fill",
                                iconColor: AppColors.primary,
                                title: "Save habit logs",
                                value: ""
                            )
                        }

                    } header: {
                        Text("Preferences")
                    }

                    // Privacy section
                    Section {
                        NavigationLink {
                            PrivacyInfoView()
                        } label: {
                            SettingsRow(
                                icon: "lock.shield.fill",
                                iconColor: .green,
                                title: "Privacy & Data",
                                value: ""
                            )
                        }

                    } header: {
                        Text("Privacy")
                    }

                    // Danger zone
                    Section {
                        Button(role: .destructive) {
                            clearAllData()
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Clear All Data")
                            }
                        }

                        Button(role: .destructive) {
                            showingDeleteAccountAlert = true
                        } label: {
                            HStack {
                                if isDeletingAccount {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Image(systemName: "person.crop.circle.badge.minus")
                                }
                                Text("Delete Account")
                            }
                        }
                        .disabled(isDeletingAccount)
                    } header: {
                        Text("Danger Zone")
                    } footer: {
                        Text("These actions cannot be undone.")
                    }
                }
                .scrollContentBackground(.hidden)
                .confirmationDialog(
                    "Delete Account",
                    isPresented: $showingDeleteAccountAlert,
                    titleVisibility: .visible
                ) {
                    Button("Delete Account", role: .destructive) {
                        Task {
                            isDeletingAccount = true
                            do {
                                try await appState.deleteAccount(modelContext: modelContext)
                                dismiss()
                            } catch {
                                deleteAccountError = error.localizedDescription
                                isDeletingAccount = false
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete your account and all your data. This cannot be undone.")
                }
                .alert("Couldn't Delete Account", isPresented: Binding(
                    get: { deleteAccountError != nil },
                    set: { if !$0 { deleteAccountError = nil } }
                )) {
                    Button("OK") { deleteAccountError = nil }
                } message: {
                    Text(deleteAccountError ?? "")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                notificationManager.checkAuthorizationStatus()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAppSelection) {
                AppSelectionView()
            }
        }
    }

    private func clearAllData() {
        // Use SyncManager to clear all SwiftData models
        SyncManager.shared.clearLocalData(modelContext: modelContext)

        // Reset local app state
        appState.hasCompletedOnboarding = false
        appState.hasCompletedFirstRunSetup = false
        appState.resetOnboardingGoal()

        dismiss()
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(title)
                .font(AppTypography.body)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

struct PrivacyInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                InfoSection(
                    title: "Your Data & Cloud Sync",
                    content: "Your goals and stats are stored locally on your device and securely synced to the cloud. This allows you to access your data across devices. Completion records and proof images stay on your device only."
                )

                InfoSection(
                    title: "Proof Verification",
                    content: "When you submit proof photos for verification, they're sent securely to our AI service. Images are processed and immediately discarded - they're never stored on our servers."
                )

                InfoSection(
                    title: "What We See",
                    content: "Your account data (goals, stats) is stored securely in our cloud database. We use this only to sync your data and never share it with third parties."
                )

                InfoSection(
                    title: "Screen Time Access",
                    content: "If you enable app blocking, we use Apple's Screen Time API. We can block apps you choose but cannot see what you do in those apps."
                )

                InfoSection(
                    title: "Account Security",
                    content: "Your account is protected by Supabase authentication. We support secure sign-in with email or Apple ID."
                )
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("Privacy & Data")
        .background(GradientBackgroundView())
    }
}

struct InfoSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text(content)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(Color.white)
        )
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(NotificationManager.shared)
        .environment(ScreenTimeManager.shared)
        .modelContainer(for: [Goal.self, UserStats.self], inMemory: true)
}
