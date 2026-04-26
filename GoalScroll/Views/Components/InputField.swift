import SwiftUI

struct InputField: View {
    let placeholder: String
    @Binding var text: String
    var isValid: Bool = false
    var maxLength: Int = 80
    var showCharacterCount: Bool = true
    var characterCountThreshold: Int = 70
    var focusState: FocusState<Bool>.Binding? = nil

    @FocusState private var isFocusedInternal: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textMuted)
                }

                TextField("", text: $text, axis: .vertical)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .focused(focusState ?? $isFocusedInternal)
                    .lineLimit(1...3)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }
            }

            // Checkmark indicator
            if isValid {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md + 4)
        .background(
            ZStack {
                // Background fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "F0F7FF").opacity(0.8),
                                Color(hex: "E8F4FD").opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Border
                Capsule()
                    .strokeBorder(
                        (focusState?.wrappedValue ?? isFocusedInternal) ? AppColors.primary.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
                    .animation(.easeInOut(duration: 0.2), value: focusState?.wrappedValue ?? isFocusedInternal)
            }
        )
        .shadow(color: AppColors.shadowColor.opacity(0.5), radius: 8, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isValid)
        .overlay(alignment: .bottomTrailing) {
            if showCharacterCount && text.count >= characterCountThreshold {
                Text("\(text.count)/\(maxLength)")
                    .font(AppTypography.caption)
                    .foregroundColor(text.count >= maxLength ? AppColors.error : AppColors.textMuted)
                    .padding(.trailing, AppSpacing.lg)
                    .padding(.top, AppSpacing.xs)
                    .offset(y: 24)
            }
        }
    }
}

struct TextAreaField: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    var focusState: FocusState<Bool>.Binding? = nil

    @FocusState private var isFocusedInternal: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textMuted)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
            }

            TextEditor(text: $text)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .focused(focusState ?? $isFocusedInternal)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
        }
        .padding(AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.inputBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .strokeBorder(
                    (focusState?.wrappedValue ?? isFocusedInternal) ? AppColors.primary.opacity(0.5) : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

#Preview {
    VStack(spacing: 40) {
        InputField(
            placeholder: "e.g. Get healthier, Learn Spanish, Feel more focused",
            text: .constant(""),
            isValid: false
        )

        InputField(
            placeholder: "e.g. Get healthier, Learn Spanish, Feel more focused",
            text: .constant("Get healthier"),
            isValid: true
        )

        TextAreaField(
            placeholder: "Why is this important to you?",
            text: .constant("")
        )
    }
    .padding()
    .background(GradientBackgroundView())
}
