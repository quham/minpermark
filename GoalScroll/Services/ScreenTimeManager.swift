import Foundation
import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
import DeviceActivity
#endif

// MARK: - Screen Time Manager

@MainActor
@Observable
class ScreenTimeManager {
    static let shared = ScreenTimeManager()

    var isAuthorized = false
    var isAvailable = false
    var isBlocking = false
    var unlockExpiryDate: Date?
    var unlockStartDate: Date?
    var allGoalsCompleted = false {
        didSet {
            enforceBlockingState()
        }
    }

    #if canImport(FamilyControls)
    // The apps/categories user has selected to block
    var selectedApps = FamilyActivitySelection() {
        didSet {
            saveSelection()
            enforceBlockingState()
        }
    }

    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let activityCenter = DeviceActivityCenter()
    #endif

    private let sharedDefaults = UserDefaults(suiteName: Constants.App.groupIdentifier)
    private let selectionKey = Constants.UserDefaultsKeys.screenTimeSelection
    private let expiryKey = Constants.UserDefaultsKeys.unlockExpiryDate
    private let startKey = Constants.UserDefaultsKeys.unlockStartDate
    private let pendingDeductionKey = Constants.UserDefaultsKeys.pendingMinuteDeduction

    private init() {
        checkAvailability()
        loadExpiry()
        loadSelection()
        enforceBlockingState()
    }

    private func loadExpiry() {
        // Load expiry date
        if let expiry = sharedDefaults?.object(forKey: expiryKey) as? Date {
            self.unlockExpiryDate = expiry
            // Check if already expired
            if expiry < Date() {
                self.unlockExpiryDate = nil
                sharedDefaults?.removeObject(forKey: expiryKey)
            }
        }
        // Load start date
        if let start = sharedDefaults?.object(forKey: startKey) as? Date {
            self.unlockStartDate = start
            // Clear if expiry is nil (break is over)
            if unlockExpiryDate == nil {
                self.unlockStartDate = nil
                sharedDefaults?.removeObject(forKey: startKey)
            }
        }
    }

    // MARK: - Availability Check

    func checkAvailability() {
        #if canImport(FamilyControls)
        isAvailable = true
        checkAuthorization()
        #else
        isAvailable = false
        #endif
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        #if canImport(FamilyControls)
        do {
            try await center.requestAuthorization(for: .individual)
            await MainActor.run {
                isAuthorized = true
                enforceBlockingState()
            }
            return true
        } catch {
            print("Screen Time authorization failed: \(error)")
            await MainActor.run {
                isAuthorized = false
            }
            return false
        }
        #else
        return false
        #endif
    }

    func checkAuthorization() {
        #if canImport(FamilyControls)
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
        case .denied, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
        #endif
    }

    // MARK: - Selection Persistence

    private func saveSelection() {
        #if canImport(FamilyControls)
        let encoder = PropertyListEncoder()
        if let data = try? encoder.encode(selectedApps) {
            sharedDefaults?.set(data, forKey: selectionKey)
        }
        #endif
    }

    private func loadSelection() {
        #if canImport(FamilyControls)
        if let data = sharedDefaults?.data(forKey: selectionKey),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectedApps = selection
        }
        #endif
    }

    // MARK: - App/Category Count

    var selectedAppCount: Int {
        #if canImport(FamilyControls)
        return selectedApps.applicationTokens.count
        #else
        return 0
        #endif
    }

    var selectedCategoryCount: Int {
        #if canImport(FamilyControls)
        return selectedApps.categoryTokens.count
        #else
        return 0
        #endif
    }

    var hasSelection: Bool {
        selectedAppCount > 0 || selectedCategoryCount > 0
    }

    // MARK: - Blocking Control

    func enforceBlockingState() {
        guard isAuthorized && isAvailable && hasSelection else { return }
        
        // If all goals are completed and "Done for the Day" is enabled, don't block
        let removeBlock = sharedDefaults?.bool(forKey: Constants.UserDefaultsKeys.removeBlockAfterAllGoals) ?? true
        if removeBlock && allGoalsCompleted {
            disableBlocking()
            return
        }

        // Don't re-enable blocking if an unlock session is still active
        if let expiry = unlockExpiryDate, expiry > Date() { return }
        enableBlocking()
    }

    func enableBlocking() {
        guard isAuthorized && isAvailable && hasSelection else { return }

        #if canImport(FamilyControls)
        // Clear any existing unlock expiry
        unlockExpiryDate = nil
        sharedDefaults?.removeObject(forKey: expiryKey)
        NotificationManager.shared.cancelUnlockNotifications()

        // Apply shields to selected apps
        store.shield.applications = selectedApps.applicationTokens.isEmpty ? nil : selectedApps.applicationTokens

        // Apply shields to selected categories
        store.shield.applicationCategories = selectedApps.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selectedApps.categoryTokens)

        // Block specific web domains from selected apps (e.g., instagram.com when Instagram is blocked)
        store.shield.webDomains = selectedApps.webDomainTokens.isEmpty ? nil : selectedApps.webDomainTokens

        // Also shield web domains in blocked categories
        store.shield.webDomainCategories = selectedApps.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selectedApps.categoryTokens)

        isBlocking = true
        #endif
    }

    func disableBlocking() {
        #if canImport(FamilyControls)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil

        isBlocking = false
        #endif
    }

    func startUnlockSession(for minutes: Int) {
        guard hasSelection else { return }

        let startDate = Date()
        let expiry = startDate.addingTimeInterval(TimeInterval(minutes * 60))

        // Save start and expiry dates
        self.unlockStartDate = startDate
        self.unlockExpiryDate = expiry
        sharedDefaults?.set(startDate, forKey: startKey)
        sharedDefaults?.set(expiry, forKey: expiryKey)

        disableBlocking()

        #if canImport(FamilyControls)
        // Schedule re-lock via DeviceActivity at the interval start.
        // Include year, month, day, hour, minute, second for precise one-time scheduling.
        let relockStartComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: expiry
        )
        let relockEndDate = expiry.addingTimeInterval(15 * 60)
        let relockEndComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: relockEndDate
        )

        let schedule = DeviceActivitySchedule(
            intervalStart: relockStartComponents,
            intervalEnd: relockEndComponents,
            repeats: false
        )

        do {
            // Stop any existing monitoring first
            activityCenter.stopMonitoring([.unlockSession])
            try activityCenter.startMonitoring(.unlockSession, during: schedule)
            print("DeviceActivity monitoring started: \(relockStartComponents) to \(relockEndComponents)")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
        #endif

        // Schedule notifications
        NotificationManager.shared.scheduleUnlockNotifications(expiryDate: expiry)
    }

    func checkUnlockStatus() {
        guard let expiry = unlockExpiryDate else { return }

        if expiry <= Date() {
            enableBlocking()
        }
    }

    func calculateMinutesUsed() -> Int {
        guard let start = unlockStartDate else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        let calculatedMinutes = Int(ceil(elapsed / 60.0))

        // Cap at selected minutes if expiry date is available
        if let expiry = unlockExpiryDate {
            let selectedMinutes = Int(expiry.timeIntervalSince(start) / 60.0)
            return min(calculatedMinutes, selectedMinutes)
        }
        return calculatedMinutes
    }

    /// Ends the unlock session early. Returns the number of minutes actually used (for deduction).
    func endUnlockSession() -> Int {
        #if canImport(FamilyControls)
        // 1. Calculate minutes used before clearing state
        let minutesUsed = calculateMinutesUsed()

        // 2. Stop DeviceActivity monitoring
        activityCenter.stopMonitoring([.unlockSession])

        // 3. Clear expiry and start date
        unlockExpiryDate = nil
        unlockStartDate = nil
        sharedDefaults?.removeObject(forKey: expiryKey)
        sharedDefaults?.removeObject(forKey: startKey)

        // 4. Cancel notifications
        NotificationManager.shared.cancelUnlockNotifications()

        // 5. Re-enable blocking
        enableBlocking()

        return minutesUsed
        #else
        return 0
        #endif
    }

    /// Process any pending minute deduction from a break that ended while app was closed
    func getPendingDeduction() -> Int {
        let pending = sharedDefaults?.integer(forKey: pendingDeductionKey) ?? 0
        if pending > 0 {
            sharedDefaults?.removeObject(forKey: pendingDeductionKey)
        }
        return pending
    }

    func temporarilyUnblock(for minutes: Int, completion: (() -> Void)? = nil) {
        startUnlockSession(for: minutes)
        completion?()
    }

    // MARK: - Clear Selection

    func clearSelection() {
        #if canImport(FamilyControls)
        selectedApps = FamilyActivitySelection()
        disableBlocking()
        #endif
    }
}

// Note: UI components (AppSelectionView, SelectionSummaryCard, BlockingStatusCard, InfoCard)
// have been moved to Views/Settings/AppSelectionView.swift for better separation of concerns.

#if canImport(DeviceActivity)
import DeviceActivity

extension DeviceActivityName {
    static let unlockSession = DeviceActivityName(Constants.DeviceActivity.unlockSessionIdentifier)
}
#endif
