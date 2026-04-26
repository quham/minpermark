import SwiftUI
import SwiftData

@main
struct GoalScrollApp: App {
    @State private var appState = AppState()
    @State private var verificationStore = VerificationStore()
    @State private var notificationManager = NotificationManager.shared
    @State private var screenTimeManager = ScreenTimeManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AnalyticsService.shared.configure()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Goal.self,
            CompletionRecord.self,
            ProofItem.self,
            UserStats.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(verificationStore)
                .environment(notificationManager)
                .environment(screenTimeManager)
                .modelContainer(sharedModelContainer)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { @MainActor in
                    // Check if unlock has expired and re-enable blocking
                    ScreenTimeManager.shared.checkUnlockStatus()
                    trackDailyOpenIfNeeded()

                    // Trigger sync when app becomes active (if authenticated)
                    if SupabaseManager.shared.isAuthenticated {
                        await SyncManager.shared.performFullSync(
                            modelContext: sharedModelContainer.mainContext
                        )
                    }
                }
            }
        }
    }

    private func trackDailyOpenIfNeeded() {
        let key = "analytics_last_daily_open"
        let today = Calendar.current.startOfDay(for: Date())
        let lastOpen = UserDefaults.standard.object(forKey: key) as? Date
        if lastOpen == nil || !Calendar.current.isDate(lastOpen!, inSameDayAs: today) {
            UserDefaults.standard.set(today, forKey: key)
            AnalyticsService.shared.capture(Constants.AnalyticsEvents.dailyOpen)
        }
    }
}
