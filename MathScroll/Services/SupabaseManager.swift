import Foundation
import Supabase
import Auth
import AuthenticationServices

// MARK: - Supabase Manager

/// Centralized manager for Supabase client, authentication, and session management
@MainActor
@Observable
final class SupabaseManager {
    static let shared = SupabaseManager()

    // MARK: - Supabase Client

    let client: SupabaseClient

    // MARK: - Auth State

    private(set) var currentUser: User?
    private(set) var currentSession: Session?
    private(set) var isAuthenticated: Bool = false
    private(set) var isLoading: Bool = true

    // MARK: - Initialization

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Constants.Supabase.url)!,
            supabaseKey: Constants.Supabase.anonKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )

        Task {
            await checkSession()
            setupAuthListener()
        }
    }

    // MARK: - Session Management

    private func checkSession() async {
        do {
            currentSession = try await client.auth.session
            currentUser = currentSession?.user
            isAuthenticated = currentUser != nil
        } catch {
            Log.network.error("Session check failed: \(error.localizedDescription)")
            isAuthenticated = false
        }
        isLoading = false
    }

    private func setupAuthListener() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    self.currentSession = session
                    self.currentUser = session?.user
                    self.isAuthenticated = session != nil

                    switch event {
                    case .signedIn:
                        Log.network.info("User signed in")
                        if let session {
                            AnalyticsService.shared.identify(userId: session.user.id, email: session.user.email)
                        }
                        NotificationCenter.default.post(name: .userDidSignIn, object: nil)
                    case .signedOut:
                        Log.network.info("User signed out")
                        AnalyticsService.shared.reset()
                        NotificationCenter.default.post(name: .userDidSignOut, object: nil)
                    case .tokenRefreshed:
                        Log.network.debug("Token refreshed")
                    default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Email Authentication

    /// Sign up with email and password
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        currentUser = response.user
        AnalyticsService.shared.capture(Constants.AnalyticsEvents.userSignedUp, properties: ["auth_method": "email"])
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        currentSession = session
        currentUser = session.user
        isAuthenticated = true
    }

    /// Sign out the current user
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        currentSession = nil
        isAuthenticated = false
    }

    // MARK: - Apple Sign In

    /// Sign in with Apple credentials
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }

        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )

        currentSession = session
        currentUser = session.user
        isAuthenticated = true
        AnalyticsService.shared.capture(Constants.AnalyticsEvents.userSignedIn, properties: ["auth_method": "apple"])

        // Update profile with Apple name if provided
        if let userId = currentUser?.id {
            var displayName = "User"
            if let fullName = credential.fullName {
                let parts = [fullName.givenName, fullName.familyName].compactMap { $0 }
                if !parts.isEmpty {
                    displayName = parts.joined(separator: " ")
                }
            }

            try await client.from("profiles")
                .update(["display_name": displayName])
                .eq("id", value: userId.uuidString)
                .execute()
        }
    }

    // MARK: - Account Deletion

    func deleteAccount() async throws {
        struct DeleteAccountResponse: Decodable {
            let success: Bool
        }
        let _: DeleteAccountResponse = try await client.functions
            .invoke(Constants.Supabase.deleteAccountFunction, options: FunctionInvokeOptions())
        // Client auto-includes Bearer token; sign out locally after server deletion
        AnalyticsService.shared.capture(Constants.AnalyticsEvents.accountDeleted)
        AnalyticsService.shared.reset()
        try await client.auth.signOut()
        currentUser = nil
        currentSession = nil
        isAuthenticated = false
    }

    // MARK: - Password Reset

    /// Send password reset email
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    // MARK: - Profile

    /// Fetch user's display name from profiles table
    func fetchDisplayName() async -> String? {
        guard let userId = currentUser?.id else { return nil }

        do {
            let response: [ProfileDTO] = try await client.from("profiles")
                .select("display_name")
                .eq("id", value: userId.uuidString)
                .execute()
                .value

            return response.first?.displayName
        } catch {
            Log.network.error("Failed to fetch display name: \(error.localizedDescription)")
            return nil
        }
    }

    /// Update user's display name
    func updateDisplayName(_ name: String) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.sessionExpired
        }

        try await client.from("profiles")
            .update(["display_name": name])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Accessors

    /// Access token for authenticated requests (Edge Functions)
    var accessToken: String? {
        currentSession?.accessToken
    }

    /// User ID
    var userId: UUID? {
        currentUser?.id
    }

    /// User email
    var userEmail: String? {
        currentUser?.email
    }
}

// MARK: - Profile DTO

private struct ProfileDTO: Decodable {
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case sessionExpired
    case networkError
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid credentials. Please try again."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .networkError:
            return "Network error. Please check your connection."
        case .userNotFound:
            return "No account found with this email."
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
    static let userDidSignOut = Notification.Name("userDidSignOut")
}
