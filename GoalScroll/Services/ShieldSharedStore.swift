import Foundation
import UIKit

final class ShieldSharedStore {
    static let shared = ShieldSharedStore()

    private enum Shared {
        static let appGroupIdentifier = "group.com.goalscroll.settings"
        static let whyKey = "shield_why"
        static let goalTitleKey = "shield_goal_title"
        static let iconFilename = "shield-icon.png"
    }

    private init() {}

    func updateFromGoal(_ goal: Goal) {
        let trimmedWhy = goal.why?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        saveWhy(trimmedWhy)
        saveGoalTitle(goal.title)
        saveIconForGoal(goal)
    }

    func saveCustomIcon(_ image: UIImage) {
        guard let url = iconURL() else { return }
        guard let data = image.pngData() else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func saveWhy(_ text: String) {
        sharedDefaults()?.set(text, forKey: Shared.whyKey)
    }

    private func saveGoalTitle(_ title: String) {
        sharedDefaults()?.set(title, forKey: Shared.goalTitleKey)
    }

    private func saveIconForGoal(_ goal: Goal) {
        guard let url = iconURL() else { return }
        let symbol = symbolName(for: goal.title)
        let configuration = UIImage.SymbolConfiguration(pointSize: 64, weight: .semibold)
        guard let image = UIImage(systemName: symbol, withConfiguration: configuration) else { return }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        let data = renderer.pngData { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }

        try? data.write(to: url, options: .atomic)
    }

    private func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: Shared.appGroupIdentifier)
    }

    private func iconURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Shared.appGroupIdentifier)?.appendingPathComponent(Shared.iconFilename)
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
