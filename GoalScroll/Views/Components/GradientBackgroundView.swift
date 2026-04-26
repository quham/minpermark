import SwiftUI

struct GradientBackgroundView: View {
    var body: some View {
        ZStack {
            // Base white
            Color.white

            // Multi-color gradient overlay
            LinearGradient(
                colors: [
                    Color(hex: "F5E6F3").opacity(0.7),
                    Color(hex: "E6F0F5").opacity(0.5),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Additional subtle radial gradient for depth
            RadialGradient(
                colors: [
                    Color(hex: "E8D5E7").opacity(0.3),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )

            RadialGradient(
                colors: [
                    Color(hex: "D4E5F7").opacity(0.2),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GradientBackgroundView()
}
