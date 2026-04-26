import Foundation

// MARK: - Onboarding Goal Draft

/// Draft goal used during onboarding flow before persisting to SwiftData
struct OnboardingGoalDraft {
    var title: String = ""
    var microHabit: String = ""
    var triggerType: TriggerType = .time
    var triggerValue: String = ""
    var triggerTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    var proofMethods: Set<ProofMethod> = []
    var importance: Int = 5
    var why: String = ""

    // MARK: - Validation

    var isGoalValid: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= Constants.Validation.minGoalLength
    }

    var isMicroHabitValid: Bool {
        microHabit.trimmingCharacters(in: .whitespacesAndNewlines).count >= Constants.Validation.minMicroHabitLength
    }

    var isTriggerValid: Bool {
        switch triggerType {
        case .time:
            return true // Time picker always has a value
        case .after, .location:
            return triggerValue.trimmingCharacters(in: .whitespacesAndNewlines).count >= Constants.Validation.minTriggerLength
        }
    }

    var isProofMethodsValid: Bool {
        !proofMethods.isEmpty
    }

    var isWhyValid: Bool {
        why.trimmingCharacters(in: .whitespacesAndNewlines).count >= Constants.Validation.minGoalLength
    }

    var missingParts: [String] {
        var missing: [String] = []
        if !isGoalValid {
            missing.append("Goal title")
        }
        if !isMicroHabitValid {
            missing.append("Micro-habit")
        }
        if !isTriggerValid {
            missing.append("Trigger details")
        }
        if !isProofMethodsValid {
            missing.append("Proof method")
        }
        if !isWhyValid {
            missing.append("Why it matters")
        }
        return missing
    }

    // MARK: - Computed Properties

    var triggerValueForStorage: String {
        switch triggerType {
        case .time:
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: triggerTime)
        case .after, .location:
            return triggerValue
        }
    }

    // MARK: - Conversion

    func toGoal() -> Goal {
        Goal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            microHabit: microHabit.trimmingCharacters(in: .whitespacesAndNewlines),
            triggerType: triggerType,
            triggerValue: triggerValueForStorage,
            proofMethods: Array(proofMethods),
            importance: importance,
            why: why.isEmpty ? nil : why.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
