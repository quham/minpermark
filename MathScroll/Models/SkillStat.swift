import Foundation
import SwiftData

@Model
final class SkillStat {
    @Attribute(.unique) var compositeKey: String = ""
    var tag: String = ""
    var kindRaw: String = SkillStatKind.skill.rawValue
    var attemptsCount: Int = 0
    var marksScored: Int = 0
    var marksPossible: Int = 0
    var recencyWeightedPct: Double = 0
    var lastAttemptedAt: Date = .distantPast

    init(tag: String, kind: SkillStatKind) {
        self.tag = tag
        self.kindRaw = kind.rawValue
        self.compositeKey = "\(kind.rawValue):\(tag)"
    }

    var kind: SkillStatKind {
        get { SkillStatKind(rawValue: kindRaw) ?? .skill }
        set { kindRaw = newValue.rawValue }
    }
}
