import SwiftUI

struct AddGoalView: View {
    var body: some View {
        NavigationStack {
            OnboardingContainerView(mode: .addGoal)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AddGoalView()
        .environment(AppState())
        .modelContainer(for: Goal.self, inMemory: true)
}
