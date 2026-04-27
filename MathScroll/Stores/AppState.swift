import Foundation

enum AppRoute: Equatable {
    case onboarding
    case freeQuestion
    case paywall
    case postPaywallDiagnostic
    case home
}

enum ActiveSheet: Identifiable {
    case settings, unlock, paywall, weeklyDigest
    var id: Int { hashValue }
}

@MainActor
@Observable
final class AppState {
    var profile: UserProfile?
    var activeSheet: ActiveSheet?

    var route: AppRoute {
        guard let profile else { return .onboarding }
        if !profile.onboardingDone { return .onboarding }
        if !profile.freeQuestionUsed { return .freeQuestion }
        if profile.entitlement?.isActive != true { return .paywall }
        return .home
    }
}
