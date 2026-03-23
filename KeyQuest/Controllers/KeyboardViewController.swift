import UIKit
import SwiftUI
import Keyboard
import Tonic

/// Child view controller hosting the piano keyboard with an 88-key overview strip.
class KeyboardViewController: UIViewController {

    // MARK: - Injected Dependencies (set by MainViewController before addChild)

    var audioEngine: NoteAudioEngine!
    var scoreViewModel: ScoreViewModel!

    // MARK: - Haptics

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: - State

    /// The currently active octave (0 = A0 range, 1 = C1 range, ... 7 = C7 range).
    /// Default is 4 (middle C octave).
    private var selectedOctave: Int = 4

    private var hostingController: UIHostingController<AnyView>?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        rebuildKeyboard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hapticGenerator.prepare()
    }

    // MARK: - Setup

    private func rebuildKeyboard() {
        // Remove old hosting controller if any
        if let old = hostingController {
            old.willMove(toParent: nil)
            old.view.removeFromSuperview()
            old.removeFromParent()
        }

        let octave = selectedOctave
        let keyboardSwiftUIView = FullKeyboardView(
            selectedOctave: octave,
            onOctaveSelected: { [weak self] newOctave in
                self?.switchOctave(to: newOctave)
            },
            onNoteOn: { [weak self] pitch in
                self?.handleNoteOn(pitch: pitch)
            },
            onNoteOff: { [weak self] pitch in
                self?.handleNoteOff(pitch: pitch)
            }
        )

        let hc = UIHostingController(rootView: AnyView(keyboardSwiftUIView))
        hc.view.backgroundColor = .clear

        if #available(iOS 16.0, *) {
            hc.sizingOptions = [.preferredContentSize]
        }

        addChild(hc)
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hc.view)

        NSLayoutConstraint.activate([
            hc.view.topAnchor.constraint(equalTo: view.topAnchor),
            hc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hc.didMove(toParent: self)
        hostingController = hc
    }

    private func switchOctave(to newOctave: Int) {
        guard newOctave != selectedOctave else { return }
        selectedOctave = newOctave
        rebuildKeyboard()
    }

    // MARK: - Note Handlers

    private func handleNoteOn(pitch: Pitch) {
        let midiNote = Int(pitch.midiNoteNumber)

        // 1. Haptic feedback first
        hapticGenerator.impactOccurred()

        // 2. Play audio immediately
        audioEngine.noteOn(midiNoteNumber: midiNote)

        // 3. Compute PitchClass and octave, then append to score
        let semitone = midiNote % 12
        let octave = (midiNote / 12) - 1  // MIDI convention: C4=60, so octave = 60/12 - 1 = 4
        if let pitchClass = PitchClass(rawValue: semitone) {
            scoreViewModel.append(pitchClass: pitchClass, octave: octave)
        }
    }

    private func handleNoteOff(pitch: Pitch) {
        let midiNote = Int(pitch.midiNoteNumber)
        audioEngine.noteOff(midiNoteNumber: midiNote)
    }
}

// MARK: - Full Keyboard View (Mini Overview + Playable Keyboard)

/// The complete keyboard area: mini 88-key overview strip on top,
/// full-size playable keyboard below.
struct FullKeyboardView: View {
    let selectedOctave: Int
    let onOctaveSelected: (Int) -> Void
    let onNoteOn: (Pitch) -> Void
    let onNoteOff: (Pitch) -> Void

    /// MIDI range for the selected octave (13 keys: C to next C)
    private var pitchRange: ClosedRange<Pitch> {
        let startMidi = (selectedOctave + 1) * 12   // C of selected octave
        let endMidi = startMidi + 12                  // C of next octave
        return Pitch(Int8(startMidi))...Pitch(Int8(endMidi))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mini 88-key overview strip
            MiniPianoStrip(
                selectedOctave: selectedOctave,
                onOctaveSelected: onOctaveSelected
            )
            .frame(height: 36)
            .padding(.horizontal, 4)
            .padding(.top, 4)

            // Playable piano keyboard
            Keyboard(
                layout: .piano(pitchRange: pitchRange),
                latching: false,
                noteOn: { pitch, _ in onNoteOn(pitch) },
                noteOff: { pitch in onNoteOff(pitch) }
            ) { pitch, isActivated in
                RealisticKeyView(
                    pitch: pitch,
                    isActivated: isActivated
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Mini 88-Key Piano Strip

/// A miniature representation of an 88-key piano. Each octave is a tappable
/// block. The selected octave is bright; inactive ones are dimmed.
struct MiniPianoStrip: View {
    let selectedOctave: Int
    let onOctaveSelected: (Int) -> Void

    /// The 88-key piano spans octaves 0 (partial: A0-B0) through 8 (partial: C8 only).
    /// We display full octave blocks 0-7 for simplicity.
    private let octaveCount = 8  // octaves 0 through 7

    var body: some View {
        GeometryReader { geo in
            let blockWidth = geo.size.width / CGFloat(octaveCount)
            let height = geo.size.height

            HStack(spacing: 0) {
                ForEach(0..<octaveCount, id: \.self) { octave in
                    MiniOctaveBlock(
                        octave: octave,
                        isSelected: octave == selectedOctave,
                        width: blockWidth,
                        height: height
                    )
                    .onTapGesture {
                        onOctaveSelected(octave)
                    }
                }
            }
        }
        .background(Color.black)
        .cornerRadius(4)
    }
}

/// A single octave block in the mini strip (7 white keys + 5 black keys).
struct MiniOctaveBlock: View {
    let octave: Int
    let isSelected: Bool
    let width: CGFloat
    let height: CGFloat

    // White key pattern per octave: C D E F G A B = 7 keys
    private let whiteKeyCount = 7
    // Black key positions relative to white keys (0-indexed):
    // Between C-D(0), D-E(1), skip, F-G(3), G-A(4), A-B(5) → skip last
    private let blackKeyOffsets: [Int] = [0, 1, 3, 4, 5]

    private var brightness: Double { isSelected ? 1.0 : 0.25 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // White keys
            HStack(spacing: 0.5) {
                ForEach(0..<whiteKeyCount, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(brightness))
                }
            }

            // Black keys overlaid
            GeometryReader { geo in
                let keyW = geo.size.width / CGFloat(whiteKeyCount)
                let blackH = height * 0.55
                let blackW = keyW * 0.65

                ForEach(blackKeyOffsets, id: \.self) { offset in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: isSelected ? 0.15 : 0.08))
                        .frame(width: blackW, height: blackH)
                        .offset(x: CGFloat(offset) * keyW + keyW - blackW / 2)
                }
            }

            // Octave label
            if isSelected {
                Text("C\(octave)")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 1)
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Realistic Piano Key Views

/// A custom key view that looks like a real piano key.
struct RealisticKeyView: View {
    let pitch: Pitch
    let isActivated: Bool

    private var isBlackKey: Bool {
        let pc = pitch.midiNoteNumber % 12
        return [1, 3, 6, 8, 10].contains(Int(pc))
    }

    var body: some View {
        if isBlackKey {
            blackKeyView
        } else {
            whiteKeyView
        }
    }

    // MARK: - White Key

    private var whiteKeyView: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 4)
                .fill(isActivated ? Color(white: 0.85) : Color.white)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: isActivated ? 1 : 3,
                    x: 0,
                    y: isActivated ? 1 : 2
                )

            VStack(spacing: 0) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.9),
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)

                Spacer()

                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: isActivated
                                ? [Color(white: 0.78), Color(white: 0.78)]
                                : [Color(white: 0.92), Color(white: 0.88)]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 12)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(white: 0.78), lineWidth: 0.5)
        )
        .padding(.horizontal, 0.5)
        .padding(.bottom, 1)
    }

    // MARK: - Black Key

    private var blackKeyView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: isActivated
                            ? [Color(white: 0.25), Color(white: 0.20)]
                            : [Color(white: 0.18), Color(white: 0.08), Color(white: 0.05)]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 0) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(isActivated ? 0.08 : 0.2),
                        Color.white.opacity(isActivated ? 0.02 : 0.05),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 15)

                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.black.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(
            color: Color.black.opacity(isActivated ? 0.2 : 0.5),
            radius: isActivated ? 1 : 3,
            x: 0,
            y: isActivated ? 1 : 3
        )
        .padding(.horizontal, 1)
    }
}
