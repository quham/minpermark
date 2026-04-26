import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) var appState
    @Query private var goals: [Goal]

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding || goals.isEmpty {
                OnboardingContainerView()
            } else {
                HomeView()
            }
        }
        .animation(.easeInOut, value: appState.hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(VerificationStore())
        .modelContainer(for: [Goal.self, CompletionRecord.self, ProofItem.self, UserStats.self], inMemory: true)
}
