import SwiftUI

enum Theme {
    static let cornerLarge: CGFloat = 28
    static let cornerMedium: CGFloat = 18
    static let cornerSmall: CGFloat = 12
    static let pad: CGFloat = 16
    static let padLarge: CGFloat = 24

    static let accent = Color.accentColor
    static let success = Color.green
    static let warning = Color.orange
    static let onSurface = Color.primary
}

extension Font {
    static let mathDisplay = Font.system(size: 56, weight: .bold, design: .rounded)
    static let mathTitle = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let mathBody = Font.system(.body, design: .rounded)
}
