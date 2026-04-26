import SwiftUI

struct ChipView: View {
    let text: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(AppTypography.subheadline)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.primary : AppColors.inputBackground)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : AppColors.inputBorder,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SuggestionChipsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        FlowLayout(spacing: AppSpacing.xs) {
            ForEach(suggestions, id: \.self) { suggestion in
                ChipView(text: suggestion) {
                    onSelect(suggestion)
                }
            }
        }
    }
}

// Flow layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

struct SelectableOptionView: View {
    let title: String
    let description: String?
    let icon: String?
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                        .frame(width: 32)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    if let description = description {
                        Text(description)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                Circle()
                    .strokeBorder(isSelected ? AppColors.primary : AppColors.inputBorder, lineWidth: 2)
                    .background(
                        Circle()
                            .fill(isSelected ? AppColors.primary : Color.clear)
                            .padding(4)
                    )
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(isSelected ? AppColors.primary.opacity(0.05) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .strokeBorder(
                        isSelected ? AppColors.primary : AppColors.inputBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        SuggestionChipsView(
            suggestions: ["Drink water", "Meditate", "Read 1 page", "Take a walk"]
        ) { selected in
            print("Selected: \(selected)")
        }

        SelectableOptionView(
            title: "Camera check-in",
            description: "Take a photo as proof",
            icon: "camera.fill",
            isSelected: true
        ) {}

        SelectableOptionView(
            title: "Short reflection",
            description: "Write a brief note",
            icon: "pencil.line",
            isSelected: false
        ) {}
    }
    .padding()
    .background(GradientBackgroundView())
}
