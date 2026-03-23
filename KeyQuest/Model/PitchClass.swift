import Foundation

/// Represents one of the twelve semitones in a chromatic octave.
enum PitchClass: Int, CaseIterable {
    case C  = 0
    case Cs = 1   // C-sharp
    case D  = 2
    case Ds = 3   // D-sharp
    case E  = 4
    case F  = 5
    case Fs = 6   // F-sharp
    case G  = 7
    case Gs = 8   // G-sharp
    case A  = 9
    case As = 10  // A-sharp
    case B  = 11

    /// Diatonic step position on the staff (0 = C through 6 = B).
    /// Accidentals share the staffStep of their lower natural neighbor.
    var staffStep: Int {
        switch self {
        case .C, .Cs: return 0
        case .D, .Ds: return 1
        case .E:      return 2
        case .F, .Fs: return 3
        case .G, .Gs: return 4
        case .A, .As: return 5
        case .B:      return 6
        }
    }

    /// Whether this pitch class is an accidental (black key).
    var isAccidental: Bool {
        switch self {
        case .Cs, .Ds, .Fs, .Gs, .As: return true
        default: return false
        }
    }

    /// Human-readable note name, e.g. "C", "F#", "A#".
    var displayName: String {
        switch self {
        case .C:  return "C"
        case .Cs: return "C#"
        case .D:  return "D"
        case .Ds: return "D#"
        case .E:  return "E"
        case .F:  return "F"
        case .Fs: return "F#"
        case .G:  return "G"
        case .Gs: return "G#"
        case .A:  return "A"
        case .As: return "A#"
        case .B:  return "B"
        }
    }
}
