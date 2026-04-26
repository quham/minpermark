import SwiftUI

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    let onBack: () -> Void

    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessMessage = false

    @FocusState private var isEmailFocused: Bool

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && email.contains("@")
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Instruction text
            Text("Enter your email address and we'll send you a link to reset your password.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: AppSpacing.sm)

            // Email field
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Email")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                TextField("", text: $email)
                    .textFieldStyle(AuthTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isEmailFocused)
                    .submitLabel(.go)
                    .onSubmit { if isFormValid { Task { await resetPassword() } } }
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

            // Success message
            if showSuccessMessage {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.success)

                    Text("Check your email")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Text("We've sent a password reset link to \(email)")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, AppSpacing.lg)
                .transition(.opacity.combined(with: .scale))
            }

            Spacer()
                .frame(height: AppSpacing.sm)

            // Reset Password button
            if !showSuccessMessage {
                PrimaryButton(
                    title: "Send Reset Link",
                    isEnabled: isFormValid && !isLoading,
                    isLoading: isLoading
                ) {
                    Task { await resetPassword() }
                }
            }

            // Back to Sign In
            Button(action: onBack) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Back to Sign In")
                        .font(AppTypography.body)
                }
                .foregroundColor(AppColors.primary)
            }

            Spacer()
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isEmailFocused = false }
        )
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
        .animation(.easeInOut(duration: 0.3), value: showSuccessMessage)
    }

    // MARK: - Actions

    private func resetPassword() async {
        isEmailFocused = false
        isLoading = true
        errorMessage = nil

        do {
            try await SupabaseManager.shared.resetPassword(email: email)
            showSuccessMessage = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        ForgotPasswordView(onBack: {})
            .padding()
    }
}
