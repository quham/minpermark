import Foundation
import Supabase

protocol QuestionBankTransport {
    func fetch(level: ExamLevel, board: ExamBoard, tier: Tier?) async throws -> [Question]
}

struct SupabaseBankTransport: QuestionBankTransport {
    let client: SupabaseClient
    func fetch(level: ExamLevel, board: ExamBoard, tier: Tier?) async throws -> [Question] {
        var query = client.from("questions")
            .select()
            .eq("level", value: level.rawValue)
            .eq("board", value: board.rawValue)
        if let tier {
            query = query.eq("tier", value: tier.rawValue)
        }
        return try await query.execute().value
    }
}

final class QuestionBankService {
    private let transport: QuestionBankTransport
    init(transport: QuestionBankTransport) { self.transport = transport }

    func fetchAvailable(level: ExamLevel, board: ExamBoard, tier: Tier?) async throws -> [Question] {
        try await transport.fetch(level: level, board: board, tier: tier)
    }
}
