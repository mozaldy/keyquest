import Foundation

/// Defines a single level in KeyQuest.
struct Level {
    let id: Int
    let title: String
    let description: String
    /// The notes this level teaches. Challenges are drawn randomly from this list.
    let targetNotes: [StaffNote]
    /// Number of correct answers required to complete the level.
    let challengeCount: Int

    /// All available levels in the game.
    static let allLevels: [Level] = [
        Level(
            id: 1,
            title: "C & E",
            description: "Learn to identify C4 and E4 on the staff",
            targetNotes: [
                StaffNote(pitchClass: .C, octave: 4),
                StaffNote(pitchClass: .E, octave: 4)
            ],
            challengeCount: 10
        )
    ]
}
