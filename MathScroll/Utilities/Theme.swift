import SwiftUI

// MARK: - App Colors
struct AppColors {
    // Primary brand colors
    static let primary = Color(hex: "4A7BF7")
    static let primaryDark = Color(hex: "3A62C4")
    static let primaryLight = Color(hex: "6B94F9")

    // Gradient colors for background
    static let gradientStart = Color(hex: "E8D5E7").opacity(0.6)
    static let gradientMiddle = Color(hex: "D4E5F7").opacity(0.4)
    static let gradientEnd = Color.white

    // Text colors
    static let textPrimary = Color(hex: "2D3142")
    static let textSecondary = Color(hex: "6B7280")
    static let textMuted = Color(hex: "9CA3AF")

    // UI colors
    static let cardBackground = Color.white
    static let inputBackground = Color(hex: "F0F4F8")
    static let inputBorder = Color(hex: "E2E8F0")
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")

    // Shadows
    static let shadowColor = Color.black.opacity(0.08)
}

// MARK: - App Typography
struct AppTypography {
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let title = Font.system(size: 24, weight: .semibold, design: .default)
    static let title2 = Font.system(size: 20, weight: .semibold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
}

// MARK: - App Spacing
struct AppSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - App Corner Radius
struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 100
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
            .shadow(color: AppColors.shadowColor, radius: 10, x: 0, y: 4)
    }

    func inputFieldStyle() -> some View {
        self
            .padding(AppSpacing.md)
            .background(AppColors.inputBackground)
            .cornerRadius(AppCornerRadius.xl)
    }
}
