import SwiftUI

struct GlassCard<Content: View>: View {
    var corner: CGFloat = Theme.cornerLarge
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Theme.pad)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .glassEffect()
    }
}
