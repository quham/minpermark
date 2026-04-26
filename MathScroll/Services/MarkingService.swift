import Foundation
import Supabase

enum MarkingError: Error, Equatable {
    case invalidResponse
    case networkFailed
}

protocol MarkingTransport {
    func invoke(question: Question, studentImage: Data, strict: Bool) async throws -> Data
}

struct EdgeFunctionMarkingTransport: MarkingTransport {
    let client: SupabaseClient
    func invoke(question: Question, studentImage: Data, strict: Bool) async throws -> Data {
        struct Body: Encodable {
            let question_image_url: String
            let mark_scheme_image_url: String
            let student_image_base64: String
        }
        let body = Body(
            question_image_url: question.questionImageURL.absoluteString,
            mark_scheme_image_url: question.markSchemeImageURL.absoluteString,
            student_image_base64: studentImage.base64EncodedString()
        )
        let response: Data = try await client.functions
            .invoke("mark-question", options: FunctionInvokeOptions(body: body))
        return response
    }
}

final class MarkingService {
    private let transport: MarkingTransport
    init(transport: MarkingTransport) { self.transport = transport }

    func mark(question: Question, studentImage: Data) async throws -> MarkingResult {
        let attempt: (Bool) async throws -> Data = { strict in
            try await self.transport.invoke(question: question, studentImage: studentImage, strict: strict)
        }
        do {
            let raw = try await attempt(false)
            return try JSONDecoder().decode(MarkingResult.self, from: raw)
        } catch is DecodingError {
            let raw = try await attempt(true)
            do {
                return try JSONDecoder().decode(MarkingResult.self, from: raw)
            } catch is DecodingError {
                throw MarkingError.invalidResponse
            }
        }
    }
}
