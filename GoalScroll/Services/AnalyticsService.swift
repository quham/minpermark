import Foundation
import PostHog

// MARK: - Analytics Service

/// Thin PostHog wrapper. Call `configure()` once at launch before any tracking.
/// Gracefully no-ops when the API key is not set (e.g. debug builds without Secrets.xcconfig).
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    // MARK: - Configuration

    func configure() {
        guard let key = Bundle.main.infoDictionary?["POSTHOG_API_KEY"] as? String,
              !key.isEmpty,
              !key.contains("YOUR_KEY") else {
            print("[Analytics] PostHog API key not configured — analytics disabled")
            return
        }

        let config = PostHogConfig(apiKey: key)
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = false
        PostHogSDK.shared.setup(config)
        print("[Analytics] PostHog analytics configured")
    }

    // MARK: - Identity

    func identify(userId: UUID, email: String?) {
        var properties: [String: Any] = [:]
        if let email {
            properties["email"] = email
        }
        PostHogSDK.shared.identify(userId.uuidString, userProperties: properties)
    }

    func reset() {
        PostHogSDK.shared.reset()
    }

    /// Updates person-level properties without changing the distinct ID.
    func setUserProperties(_ properties: [String: Any]) {
        PostHogSDK.shared.identify(
            PostHogSDK.shared.getDistinctId(),
            userProperties: properties
        )
    }

    // MARK: - Event Capture

    func capture(_ event: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.capture(event, properties: properties)
    }
}
