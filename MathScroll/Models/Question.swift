import Foundation

struct Question: Identifiable, Codable, Hashable {
    let id: String
    let board: ExamBoard
    let level: ExamLevel
    let tier: Tier?
    let paperYear: Int
    let paperCode: String
    let questionNumber: String
    let questionImageURL: URL
    let markSchemeImageURL: URL
    let totalMarks: Int
    let subtopicTags: [String]
    let skillTags: [String]
    let difficulty: Int

    enum CodingKeys: String, CodingKey {
        case id, board, level, tier, difficulty
        case paperYear = "paper_year"
        case paperCode = "paper_code"
        case questionNumber = "question_number"
        case questionImageURL = "question_image_url"
        case markSchemeImageURL = "mark_scheme_image_url"
        case totalMarks = "total_marks"
        case subtopicTags = "subtopic_tags"
        case skillTags = "skill_tags"
    }
}
