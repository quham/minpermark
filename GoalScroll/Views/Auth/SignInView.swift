import SwiftUI
import AuthenticationServices

// MARK: - Sign In View

struct SignInView: View {
    let onSignUp: () -> Void
    let onForgotPassword: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        !password.isEmpty
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
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
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { if isFormValid { Task { await signIn() } } }
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

            // Sign In button
            PrimaryButton(
                title: "Sign In",
                isEnabled: isFormValid && !isLoading,
                isLoading: isLoading
            ) {
                Task { await signIn() }
            }

            // Forgot password
            Button(action: onForgotPassword) {
                Text("Forgot password?")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.primary)
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
            SignInWithAppleButton(.signIn) { request in
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

            // Sign Up link
            HStack(spacing: AppSpacing.xs) {
                Text("Don't have an account?")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)

                Button(action: onSignUp) {
                    Text("Sign Up")
                        .font(AppTypography.body.bold())
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
        )
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }

    // MARK: - Actions

    private func signIn() async {
        focusedField = nil
        isLoading = true
        errorMessage = nil

        do {
            try await SupabaseManager.shared.signIn(email: email, password: password)
            AnalyticsService.shared.capture(Constants.AnalyticsEvents.userSignedIn, properties: ["auth_method": "email"])
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
            // Don't show error for user cancellation
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}

// MARK: - Auth Text Field Style

struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(AppSpacing.md)
            .background(AppColors.inputBackground)
            .foregroundColor(.black)
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(AppColors.inputBorder, lineWidth: 1)
            )
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        SignInView(onSignUp: {}, onForgotPassword: {})
            .padding()
    }
}
