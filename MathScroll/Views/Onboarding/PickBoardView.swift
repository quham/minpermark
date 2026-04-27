import SwiftUI

struct PickBoardView: View {
    @Bindable var profile: UserProfile
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Which exam board?").font(.mathTitle)
            ForEach(ExamBoard.allCases, id: \.self) { board in
                Button {
                    profile.board = board
                    onNext()
                } label: {
                    GlassCard { Text(board.rawValue.uppercased()).font(.mathBody).frame(maxWidth: .infinity) }
                }
                .buttonStyle(.plain)
            }
        }.padding()
    }
}
