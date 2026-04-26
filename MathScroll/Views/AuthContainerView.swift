import SwiftUI

// MARK: - Auth Mode

enum AuthMode {
    case signIn
    case signUp
    case forgotPassword
}

// MARK: - Auth Container View

/// Container view that manages the authentication flow
struct AuthContainerView: View {
    @State private var authMode: AuthMode = .signIn

    var body: some View {
        ZStack {
            GradientBackgroundView()

            VStack(spacing: 0) {
                // Logo section
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "target")
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(AppColors.primary)

                    Text(Constants.App.name)
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)

                    Text(tagline)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, AppSpacing.xxxl)

                Spacer()
                    .frame(height: AppSpacing.xxl)

                // Auth form
                switch authMode {
                case .signIn:
                    SignInView(
                        onSignUp: { withAnimation { authMode = .signUp } },
                        onForgotPassword: { withAnimation { authMode = .forgotPassword } }
                    )
                case .signUp:
                    SignUpView(
                        onSignIn: { withAnimation { authMode = .signIn } }
                    )
                case .forgotPassword:
                    ForgotPasswordView(
                        onBack: { withAnimation { authMode = .signIn } }
                    )
                }

                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private var tagline: String {
        switch authMode {
        case .signIn:
            return "Welcome back"
        case .signUp:
            return "Start your journey"
        case .forgotPassword:
            return "Reset your password"
        }
    }
}

#Preview {
    AuthContainerView()
}
