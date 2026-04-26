import Foundation
import UIKit
import Supabase
import Auth

// MARK: - Protocol

protocol GeminiServiceProtocol {
    func suggestMicroHabits(goalTitle: String) async throws -> [String]
    func verifyProof(goal: Goal, proofItems: [ProofItem]) async throws -> VerificationResult
}

// MARK: - Edge Function Request/Response Models

struct EdgeSuggestionsRequest: Encodable {
    let goalTitle: String

    private enum CodingKeys: String, CodingKey {
        case goalTitle = "goal_title"
    }
}

struct EdgeSuggestionsResponse: Decodable {
    let suggestions: [String]
}

struct EdgeVerifyRequest: Encodable {
    let goal: EdgeGoalInfo
    let proofItems: [EdgeProofItem]

    private enum CodingKeys: String, CodingKey {
        case goal
        case proofItems = "proof_items"
    }
}

struct EdgeGoalInfo: Encodable {
    let title: String
    let microHabit: String
    let triggerType: String
    let triggerValue: String

    private enum CodingKeys: String, CodingKey {
        case title
        case microHabit = "micro_habit"
        case triggerType = "trigger_type"
        case triggerValue = "trigger_value"
    }
}

struct EdgeProofItem: Encodable {
    let type: String
    let imageBase64: String?
    let text: String?

    private enum CodingKeys: String, CodingKey {
        case type
        case imageBase64 = "image_base64"
        case text
    }
}

struct EdgeVerifyResponse: Decodable {
    let status: String
    let confidence: Double?
    let reason: String?
}

// MARK: - Verification Result

struct VerificationResult {
    let status: VerificationStatus
    let confidence: Double?
    let reason: String?
    let verifiedAt: Date

    init(
        status: VerificationStatus,
        confidence: Double? = nil,
        reason: String? = nil,
        verifiedAt: Date = Date()
    ) {
        self.status = status
        self.confidence = confidence
        self.reason = reason
        self.verifiedAt = verifiedAt
    }
}

// MARK: - Service Implementation (Supabase Edge Functions)

@MainActor
class GeminiService: GeminiServiceProtocol {

    init() {}

    // MARK: - Suggest Micro Habits

    func suggestMicroHabits(goalTitle: String) async throws -> [String] {
        // Check if authenticated
        guard SupabaseManager.shared.isAuthenticated else {
            Log.network.warning("Not authenticated, using default suggestions")
            return getDefaultSuggestions(for: goalTitle)
        }

        do {
            let request = EdgeSuggestionsRequest(goalTitle: goalTitle)

            let response: EdgeSuggestionsResponse = try await SupabaseManager.shared.client.functions
                .invoke(
                    Constants.Supabase.suggestionsFunction,
                    options: FunctionInvokeOptions(body: request)
                )

            return response.suggestions

        } catch {
            Log.network.error("Edge function error: \(error.localizedDescription)")
            // Fall back to default suggestions on error
            return getDefaultSuggestions(for: goalTitle)
        }
    }

    // MARK: - Verify Proof

    func verifyProof(goal: Goal, proofItems: [ProofItem]) async throws -> VerificationResult {
        guard !proofItems.isEmpty else {
            return VerificationResult(status: .failed, reason: "Proof is required")
        }

        // Check if authenticated
        guard SupabaseManager.shared.isAuthenticated else {
            Log.network.warning("Not authenticated, auto-passing verification")
            return VerificationResult(status: .passed, confidence: 0.5, reason: "Verification unavailable - proof accepted")
        }

        do {
            let proofPayload = proofItems.map { item in
                EdgeProofItem(
                    type: item.type.rawValue,
                    imageBase64: imageBase64(from: item.fileURL),
                    text: item.text
                )
            }

            let goalInfo = EdgeGoalInfo(
                title: goal.title,
                microHabit: goal.microHabit,
                triggerType: goal.triggerType.rawValue,
                triggerValue: goal.triggerValue
            )

            let request = EdgeVerifyRequest(goal: goalInfo, proofItems: proofPayload)

            let response: EdgeVerifyResponse = try await SupabaseManager.shared.client.functions
                .invoke(
                    Constants.Supabase.verifyFunction,
                    options: FunctionInvokeOptions(body: request)
                )

            var status = VerificationStatus(rawValue: response.status.lowercased()) ?? .passed
            if status == .uncertain {
                status = .passed
            }

            return VerificationResult(
                status: status,
                confidence: response.confidence,
                reason: response.reason,
                verifiedAt: Date()
            )

        } catch {
            Log.network.error("Verification edge function error: \(error.localizedDescription)")
            // Fail open on network errors
            return VerificationResult(
                status: .passed,
                confidence: 0.5,
                reason: LocalizedStrings.networkError
            )
        }
    }

    // MARK: - Private Helpers

    private func imageBase64(from fileURL: String?) -> String? {
        guard let urlString = fileURL,
              let url = URL(string: urlString),
              let imageData = try? Data(contentsOf: url),
              let image = UIImage(data: imageData),
              let resizedData = resizeImage(
                image,
                maxDimension: Constants.Image.maxDimension,
                compressionQuality: Constants.Image.compressionQuality
              ) else {
            return nil
        }

        return resizedData.base64EncodedString()
    }

    private func resizeImage(
        _ image: UIImage,
        maxDimension: CGFloat,
        compressionQuality: CGFloat
    ) -> Data? {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        if ratio >= 1 {
            return image.jpegData(compressionQuality: compressionQuality)
        }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }

    private func getDefaultSuggestions(for goal: String) -> [String] {
        let lowercased = goal.lowercased()

        if lowercased.contains("health") || lowercased.contains("fit") || lowercased.contains("exercise") {
            return ["Do 5 pushups", "Walk for 5 minutes", "Drink a glass of water", "Stretch for 2 minutes", "Take the stairs once", "Do 10 jumping jacks"]
        } else if lowercased.contains("spanish") || lowercased.contains("language") || lowercased.contains("learn") {
            return ["Learn 1 new word", "Practice for 5 minutes", "Listen to 1 podcast minute", "Read 1 sentence aloud", "Write 3 words", "Watch 1 minute of content"]
        } else if lowercased.contains("read") || lowercased.contains("book") {
            return ["Read 1 page", "Read for 5 minutes", "Read 1 paragraph", "Open my book", "Highlight 1 quote", "Read before bed"]
        } else if lowercased.contains("meditat") || lowercased.contains("mindful") || lowercased.contains("focus") || lowercased.contains("calm") {
            return ["Breathe deeply 5 times", "Sit quietly for 1 minute", "Notice 3 things around me", "Close eyes for 30 seconds", "Do a body scan", "Practice gratitude"]
        } else if lowercased.contains("write") || lowercased.contains("journal") {
            return ["Write 1 sentence", "Journal for 2 minutes", "Write 3 words", "Open my notebook", "Describe my mood", "List 1 thing I'm grateful for"]
        } else if lowercased.contains("sleep") || lowercased.contains("rest") {
            return ["Set a bedtime alarm", "Put phone away 10 min early", "Dim the lights", "Avoid screens after 9pm", "Read in bed", "Do a relaxation exercise"]
        } else {
            return ["Do it for 2 minutes", "Take the first small step", "Start and stop if needed", "Do the bare minimum version", "Just show up", "Commit to 1 minute"]
        }
    }
}

// MARK: - Errors

enum GeminiError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case invalidResponse
    case noAPIKey
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .requestFailed: return "API request failed"
        case .invalidResponse: return "Invalid API response"
        case .noAPIKey: return "No API key configured"
        case .notAuthenticated: return "Not authenticated"
        }
    }
}

// MARK: - Mock Service for Testing

class MockGeminiService: GeminiServiceProtocol {
    func suggestMicroHabits(goalTitle: String) async throws -> [String] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        return [
            "Do it for just 2 minutes",
            "Take the smallest possible step",
            "Start and see what happens",
            "Commit to showing up",
            "Do the easy version",
            "Just begin"
        ]
    }

    func verifyProof(goal: Goal, proofItems: [ProofItem]) async throws -> VerificationResult {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)

        return VerificationResult(
            status: .passed,
            confidence: 0.92,
            reason: "Great job completing your habit!"
        )
    }
}
