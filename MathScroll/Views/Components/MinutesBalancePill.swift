import SwiftUI

struct MinutesBalancePill: View {
    var minutes: Int
    var body: some View {
        GlassCapsule {
            Image(systemName: "clock.fill").foregroundStyle(.tint)
            Text("\(minutes) min").font(.mathBody.weight(.semibold))
                .contentTransition(.numericText())
        }
    }
}
