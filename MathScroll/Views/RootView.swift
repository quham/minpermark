import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            switch appState.route {
            case .onboarding:
                OnboardingContainerView(profile: profileOrCreate())
            case .freeQuestion, .home:
                MainTabView(profile: profileOrCreate())
            case .paywall:
                PaywallView()
            case .postPaywallDiagnostic:
                DiagnosticView(profile: profileOrCreate()) {
                    profileOrCreate().onboardingDone = true
                    try? context.save()
                }
            }
        }
        .onAppear { appState.profile = profileOrCreate() }
    }

    private func profileOrCreate() -> UserProfile {
        if let p = profiles.first { return p }
        let p = UserProfile()
        context.insert(p)
        try? context.save()
        return p
    }
}
