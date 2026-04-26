import Foundation

enum ExamLevel: String, Codable, CaseIterable, Hashable {
    case gcse, asLevel, aLevel
}

enum ExamBoard: String, Codable, CaseIterable, Hashable {
    case edexcel, aqa, ocr
}

enum Tier: String, Codable, CaseIterable, Hashable {
    case foundation, higher
}

enum MarkingMode: String, Codable, Hashable {
    case ai, selfMark
}

enum LedgerSource: String, Codable, Hashable {
    case earned, spent, dailyCapAdjustment, manualAdjustment
}

enum SkillStatKind: String, Codable, Hashable {
    case subtopic, skill
}
