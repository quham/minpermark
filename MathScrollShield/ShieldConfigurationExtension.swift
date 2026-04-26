import ManagedSettingsUI
import ManagedSettings
import FamilyControls
import UIKit

// MARK: - Shield Configuration Extension

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // MARK: - Shared Constants
    // Note: These constants must stay in sync with Constants.swift in the main app
    private enum SharedConstants {
        static let appGroupIdentifier = "group.com.mathscroll.settings"
        static let goalTitleKey = "shield_goal_title"
        static let whyKey = "shield_why"
        static let iconFilename = "shield-icon.png"
    }

    // MARK: - Configuration

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let goalTitle = sharedDefaults()?.string(forKey: SharedConstants.goalTitleKey) ?? "your goal"
        let goalWhy = sharedDefaults()?.string(forKey: SharedConstants.whyKey) ?? ""

        let subtitleText: String
        if !goalWhy.isEmpty {
            subtitleText = "You said \(goalTitle) matters because \(goalWhy)"
        } else {
            subtitleText = "You said \(goalTitle) matters."
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemIndigo,
            icon: loadIcon(goalTitle: goalTitle),
            title: ShieldConfiguration.Label(text: "This moment matters.", color: .label),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Return to focus", color: .systemBlue),
            primaryButtonBackgroundColor: UIColor.systemBackground
        )
    }

    // MARK: - Private Helpers

    private func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: SharedConstants.appGroupIdentifier)
    }

    private func loadIcon(goalTitle: String) -> UIImage? {
        if let url = iconURL(),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }

        return UIImage(systemName: symbolName(for: goalTitle))
    }

    private func iconURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedConstants.appGroupIdentifier)?.appendingPathComponent(SharedConstants.iconFilename)
    }

    private func symbolName(for text: String) -> String {
        let lowercased = text.lowercased()

        if lowercased.contains("health") || lowercased.contains("fit") || lowercased.contains("exercise") {
            return "handshake.fill"
        }

        if lowercased.contains("spanish") || lowercased.contains("language") || lowercased.contains("learn") {
            return "book.fill"
        }

        if lowercased.contains("read") || lowercased.contains("book") {
            return "books.vertical.fill"
        }

        if lowercased.contains("meditat") || lowercased.contains("mindful") || lowercased.contains("focus") {
            return "brain.head.profile"
        }

        if lowercased.contains("write") || lowercased.contains("journal") {
            return "pencil"
        }

        return "hand.raised.fill"
    }
}
