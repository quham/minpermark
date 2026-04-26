import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

// MARK: - Device Activity Monitor Extension

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    // MARK: - Shared Constants
    // Note: These constants must stay in sync with Constants.swift in the main app
    private enum SharedConstants {
        static let groupIdentifier = "group.com.mathscroll.settings"
        static let selectionKey = "ScreenTimeAppSelection"
        static let expiryKey = "unlockExpiryDate"
        static let startKey = "unlockStartDate"
        static let pendingDeductionKey = "pendingMinuteDeduction"
        static let unlockSessionIdentifier = "com.mathscroll.unlockSession"
    }

    // MARK: - Properties

    let store = ManagedSettingsStore()
    let groupIdentifier = SharedConstants.groupIdentifier
    let selectionKey = SharedConstants.selectionKey
    let expiryKey = SharedConstants.expiryKey
    let startKey = SharedConstants.startKey
    let pendingDeductionKey = SharedConstants.pendingDeductionKey

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("[MathScrollMonitor] intervalDidStart for: \(activity.rawValue)")

        guard activity == .unlockSession else { return }

        // Calculate minutes used and save for main app to deduct
        calculateAndSavePendingDeduction()

        clearUnlockExpiry()
        reapplyShields()
        DeviceActivityCenter().stopMonitoring([activity])
        print("[MathScrollMonitor] Break over. Apps re-locked.")
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        print("[MathScrollMonitor] intervalWillEndWarning for: \(activity.rawValue)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("[MathScrollMonitor] intervalDidEnd for: \(activity.rawValue)")
        if activity == .unlockSession {
            // Calculate minutes used and save for main app to deduct (backup)
            calculateAndSavePendingDeduction()
            clearUnlockExpiry()
            reapplyShields()
        }
    }

    private func calculateAndSavePendingDeduction() {
        let sharedDefaults = UserDefaults(suiteName: groupIdentifier)
        if let start = sharedDefaults?.object(forKey: startKey) as? Date,
           let expiry = sharedDefaults?.object(forKey: expiryKey) as? Date {
            // Calculate intended duration (selected minutes)
            let intendedDuration = expiry.timeIntervalSince(start)
            let selectedMinutes = Int(intendedDuration / 60.0)

            // Calculate actual elapsed, capped at selected
            let elapsed = Date().timeIntervalSince(start)
            let calculatedMinutes = Int(ceil(elapsed / 60.0))
            let minutesUsed = min(calculatedMinutes, selectedMinutes)

            sharedDefaults?.set(minutesUsed, forKey: pendingDeductionKey)
            print("[MathScrollMonitor] Saved pending deduction: \(minutesUsed) minutes (selected: \(selectedMinutes))")
        }
    }

    private func clearUnlockExpiry() {
        let sharedDefaults = UserDefaults(suiteName: groupIdentifier)
        sharedDefaults?.removeObject(forKey: expiryKey)
        sharedDefaults?.removeObject(forKey: startKey)
        print("[MathScrollMonitor] Cleared unlock expiry and start dates")
    }

    private func reapplyShields() {
        let sharedDefaults = UserDefaults(suiteName: groupIdentifier)

        guard let data = sharedDefaults?.data(forKey: selectionKey),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            print("[MathScrollMonitor] No selection data found, skipping shield reapply")
            return
        }

        // Re-apply shields
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)

        print("[MathScrollMonitor] Shields reapplied - apps: \(selection.applicationTokens.count), categories: \(selection.categoryTokens.count), webDomains: \(selection.webDomainTokens.count)")
    }
}

// MARK: - DeviceActivityName Extension

extension DeviceActivityName {
    // Note: Must stay in sync with Constants.DeviceActivity.unlockSessionIdentifier in main app
    static let unlockSession = DeviceActivityName("com.mathscroll.unlockSession")
}
