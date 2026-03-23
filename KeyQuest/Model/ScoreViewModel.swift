import Foundation
import Combine

/// Observable list of notes forming the current score.
/// Pure model — no knowledge of audio, layout, or rendering.
class ScoreViewModel: ObservableObject {
    @Published var notes: [StaffNote] = []

    /// Add a new note to the score.
    func append(pitchClass: PitchClass, octave: Int = 4) {
        let note = StaffNote(pitchClass: pitchClass, octave: octave)
        notes.append(note)
    }

    /// Remove all notes.
    func clear() {
        notes = []
    }
}
