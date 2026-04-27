import SwiftUI

struct PickTierView: View {
    @Bindable var profile: UserProfile
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Foundation or Higher?").font(.mathTitle)
            ForEach(Tier.allCases, id: \.self) { tier in
                Button {
                    profile.tier = tier
                    onNext()
                } label: {
                    GlassCard { Text(tier.rawValue.capitalized).font(.mathBody).frame(maxWidth: .infinity) }
                }
                .buttonStyle(.plain)
            }
        }.padding()
    }
}
