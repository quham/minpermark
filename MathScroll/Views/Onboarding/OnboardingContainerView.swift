import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var context
    @Bindable var profile: UserProfile
    @State private var step: Int = 0

    var body: some View {
        VStack {
            switch step {
            case 0: PickLevelView(profile: profile, onNext: advance)
            case 1: PickBoardView(profile: profile, onNext: advance)
            case 2:
                if profile.level == .gcse { PickTierView(profile: profile, onNext: advance) }
                else { Color.clear.onAppear { advance() } }
            case 3: DailyCapView(profile: profile, onNext: advance)
            case 4: PickAppsView(profile: profile, onNext: advance)
            default: Color.clear.onAppear {
                profile.onboardingDone = true
                try? context.save()
            }
            }
        }
        .animation(.spring, value: step)
    }

    private func advance() { step += 1 }
}
