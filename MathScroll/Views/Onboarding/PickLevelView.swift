import SwiftUI

struct PickLevelView: View {
    @Bindable var profile: UserProfile
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("What are you studying?").font(.mathTitle)
            ForEach(ExamLevel.allCases, id: \.self) { level in
                Button {
                    profile.level = level
                    onNext()
                } label: {
                    GlassCard { Text(label(for: level)).font(.mathBody).frame(maxWidth: .infinity) }
                }
                .buttonStyle(.plain)
            }
        }.padding()
    }

    private func label(for level: ExamLevel) -> String {
        switch level { case .gcse: "GCSE"; case .asLevel: "AS Level"; case .aLevel: "A-Level" }
    }
}
