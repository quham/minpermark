import SwiftUI
import AuthenticationServices

// MARK: - Sign Up View

struct SignUpView: View {
    let onSignIn: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessMessage = false

    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
        case confirmPassword
    }

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }

    private var passwordsMatch: Bool {
        password == confirmPassword || confirmPassword.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
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
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }

                // Password field
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Password")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    SecureField("", text: $password)
                        .textFieldStyle(AuthTextFieldStyle())
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirmPassword }
                }

                // Confirm Password field
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Confirm Password")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    SecureField("", text: $confirmPassword)
                        .textFieldStyle(AuthTextFieldStyle())
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.go)
                        .onSubmit { if isFormValid { Task { await signUp() } } }

                    if !passwordsMatch {
                        Text("Passwords don't match")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                    }
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
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.success)

                        Text("Check your email to confirm your account")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, AppSpacing.md)
                    .transition(.opacity.combined(with: .scale))
                }

                Spacer()
                    .frame(height: AppSpacing.sm)

                // Sign Up button
                PrimaryButton(
                    title: "Create Account",
                    isEnabled: isFormValid && !isLoading && !showSuccessMessage,
                    isLoading: isLoading
                ) {
                    Task { await signUp() }
                }

                // Divider
                HStack(spacing: AppSpacing.md) {
                    Rectangle()
                        .fill(AppColors.inputBorder)
                        .frame(height: 1)

                    Text("or")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)

                    Rectangle()
                        .fill(AppColors.inputBorder)
                        .frame(height: 1)
                }

                // Apple Sign In
                SignInWithAppleButton(.signUp) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task { await handleAppleSignIn(result) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .frame(maxWidth: 375)
                .cornerRadius(AppCornerRadius.full)

                Spacer()
                    .frame(height: AppSpacing.md)

                // Sign In link
                HStack(spacing: AppSpacing.xs) {
                    Text("Already have an account?")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)

                    Button(action: onSignIn) {
                        Text("Sign In")
                            .font(AppTypography.body.bold())
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
        )
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
        .animation(.easeInOut(duration: 0.3), value: showSuccessMessage)
    }

    // MARK: - Actions

    private func signUp() async {
        focusedField = nil
        isLoading = true
        errorMessage = nil

        do {
            try await SupabaseManager.shared.signUp(
                email: email,
                password: password
            )
            showSuccessMessage = true
            AnalyticsService.shared.capture(Constants.AnalyticsEvents.userSignedUp, properties: ["auth_method": "email"])
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                do {
                    try await SupabaseManager.shared.signInWithApple(credential: appleIDCredential)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        SignUpView(onSignIn: {})
            .padding()
    }
}
