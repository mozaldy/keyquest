import Foundation

/// A single note committed to the score.
struct StaffNote: Identifiable {
    let id: UUID
    let pitchClass: PitchClass
    let octave: Int

    init(pitchClass: PitchClass, octave: Int = 4) {
        self.id = UUID()
        self.pitchClass = pitchClass
        self.octave = octave
    }

    /// MIDI note number. C4 = 60, B4 = 71, C5 = 72.
    var midiNoteNumber: Int {
        60 + pitchClass.rawValue + (octave - 4) * 12
    }
}
