import Foundation

/// Persists level completion status and scores to UserDefaults.
struct LevelProgress {
    private static let completedLevelsKey = "completedLevels"
    private static let bestScoresKey = "bestScores"

    /// Returns true if the given level has been completed at least once.
    static func isCompleted(levelId: Int) -> Bool {
        let completed = UserDefaults.standard.array(forKey: completedLevelsKey) as? [Int] ?? []
        return completed.contains(levelId)
    }

    /// Returns true if the given level is unlocked.
    /// Level 1 is always unlocked. Others unlock when the previous level is completed.
    static func isUnlocked(levelId: Int) -> Bool {
        if levelId <= 1 { return true }
        return isCompleted(levelId: levelId - 1)
    }

    /// Mark a level as completed and save the score (number of mistakes).
    static func complete(levelId: Int, mistakes: Int) {
        var completed = UserDefaults.standard.array(forKey: completedLevelsKey) as? [Int] ?? []
        if !completed.contains(levelId) {
            completed.append(levelId)
            UserDefaults.standard.set(completed, forKey: completedLevelsKey)
        }

        // Save best score (fewer mistakes = better)
        var scores = UserDefaults.standard.dictionary(forKey: bestScoresKey) as? [String: Int] ?? [:]
        let key = "\(levelId)"
        if let existing = scores[key] {
            scores[key] = min(existing, mistakes)
        } else {
            scores[key] = mistakes
        }
        UserDefaults.standard.set(scores, forKey: bestScoresKey)
    }

    /// Returns the best score (fewest mistakes) for a level, or nil if not completed.
    static func bestScore(levelId: Int) -> Int? {
        let scores = UserDefaults.standard.dictionary(forKey: bestScoresKey) as? [String: Int] ?? [:]
        return scores["\(levelId)"]
    }

    /// Star rating: 0 mistakes = 3 stars, 1-2 = 2 stars, 3-4 = 1 star, 5+ = 0 stars.
    static func stars(forMistakes mistakes: Int) -> Int {
        switch mistakes {
        case 0: return 3
        case 1...2: return 2
        case 3...4: return 1
        default: return 0
        }
    }
}
