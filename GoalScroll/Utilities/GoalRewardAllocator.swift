import Foundation

struct GoalRewardAllocator {
    struct AllocationEntry {
        let id: UUID
        let baseMinutes: Int
        let remainder: Double
        let importance: Int
    }

    static func allocation(for goals: [Goal], totalMinutes: Int) -> [UUID: Int] {
        guard !goals.isEmpty else { return [:] }

        if totalMinutes <= 0 {
            return goals.reduce(into: [:]) { $0[$1.id] = 0 }
        }

        let totalImportance = goals.reduce(0) { $0 + max($1.importance, 0) }
        guard totalImportance > 0 else {
            return goals.reduce(into: [:]) { $0[$1.id] = 0 }
        }

        var entries: [AllocationEntry] = []
        var baseMinutesByID: [UUID: Int] = [:]
        var baseTotal = 0

        for goal in goals {
            let importance = max(goal.importance, 0)
            let rawMinutes = (Double(totalMinutes) * Double(importance)) / Double(totalImportance)
            let baseMinutes = Int(floor(rawMinutes))
            let remainder = rawMinutes - Double(baseMinutes)

            baseTotal += baseMinutes
            baseMinutesByID[goal.id] = baseMinutes
            entries.append(AllocationEntry(id: goal.id, baseMinutes: baseMinutes, remainder: remainder, importance: importance))
        }

        var remaining = totalMinutes - baseTotal
        if remaining > 0 {
            let sortedEntries = entries.sorted {
                if $0.remainder != $1.remainder {
                    return $0.remainder > $1.remainder
                }
                if $0.importance != $1.importance {
                    return $0.importance > $1.importance
                }
                return $0.id.uuidString < $1.id.uuidString
            }

            for entry in sortedEntries.prefix(remaining) {
                baseMinutesByID[entry.id, default: 0] += 1
            }
        }

        return baseMinutesByID
    }

    static func applyAllocation(_ allocation: [UUID: Int], to goals: [Goal]) -> Bool {
        var didUpdate = false
        for goal in goals {
            let minutes = allocation[goal.id] ?? 0
            if goal.dailyMinutesReward != minutes {
                goal.dailyMinutesReward = minutes
                didUpdate = true
            }
        }
        return didUpdate
    }
}
