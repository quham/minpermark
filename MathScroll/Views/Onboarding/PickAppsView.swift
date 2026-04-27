import SwiftUI
import FamilyControls

struct PickAppsView: View {
    @Bindable var profile: UserProfile
    var onNext: () -> Void
    @State private var picker: FamilyActivitySelection = .init()
    @State private var showingPicker = false

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Apps to block").font(.mathTitle)
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pick the apps that stay locked until you earn minutes.")
                        .font(.mathBody)
                    Button("Choose apps") { showingPicker = true }
                }
            }
            Button("Continue") {
                profile.blockedAppTokens = (try? JSONEncoder().encode(picker)) ?? Data()
                onNext()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .familyActivityPicker(isPresented: $showingPicker, selection: $picker)
    }
}
