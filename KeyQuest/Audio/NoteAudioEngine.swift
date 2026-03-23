import AVFoundation
import AudioKit

/// Manages the AudioKit audio engine and MIDISampler for piano playback.
/// Plain class — not a view controller, not ObservableObject, not a singleton.
class NoteAudioEngine {
    private let engine = AudioEngine()
    private let sampler = MIDISampler()

    init() {
        // Connect sampler as the engine output
        engine.output = sampler

        // Start the audio engine first
        do {
            try engine.start()
        } catch {
            print("[NoteAudioEngine] Failed to start engine: \(error)")
        }

        // Load the Piano SoundFont from the app bundle
        loadSoundFont()

        // Send a silent warm-up pulse to eliminate first-note latency
        warmUp()

        // Register for audio session interruption notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        engine.stop()
    }

    // MARK: - Public Interface

    /// Start playing a note at the given MIDI number (velocity 90).
    func noteOn(midiNoteNumber: Int) {
        try? sampler.play(noteNumber: MIDINoteNumber(midiNoteNumber),
                          velocity: 90,
                          channel: 0)
    }

    /// Stop playing a note at the given MIDI number.
    func noteOff(midiNoteNumber: Int) {
        try? sampler.stop(noteNumber: MIDINoteNumber(midiNoteNumber), channel: 0)
    }

    /// Stop the audio engine (call on background entry).
    func stop() {
        engine.stop()
    }

    /// Start the audio engine (call on foreground return).
    func start() {
        do {
            try engine.start()
        } catch {
            print("[NoteAudioEngine] Failed to restart engine: \(error)")
        }
    }

    // MARK: - Private

    private func loadSoundFont() {
        // Try loading with loadInstrument(url:) first (most direct)
        if let url = Bundle.main.url(forResource: "Piano", withExtension: "sf2") {
            do {
                try sampler.loadInstrument(url: url)
                print("[NoteAudioEngine] Loaded SoundFont via loadInstrument(url:)")
                return
            } catch {
                print("[NoteAudioEngine] loadInstrument(url:) failed: \(error)")
            }

            // Fallback: try loadSoundFont with explicit preset/bank
            do {
                try sampler.loadSoundFont("Piano", preset: 0, bank: 0, in: Bundle.main)
                print("[NoteAudioEngine] Loaded SoundFont via loadSoundFont()")
                return
            } catch {
                print("[NoteAudioEngine] loadSoundFont() failed: \(error)")
            }

            // Fallback: try loadSoundFont with preset 0, bank 0, using General MIDI conventions
            do {
                try sampler.loadSoundFont("Piano", preset: 0, bank: 0)
                print("[NoteAudioEngine] Loaded SoundFont via loadSoundFont() no bundle")
                return
            } catch {
                print("[NoteAudioEngine] All SoundFont loading methods failed: \(error)")
            }
        } else {
            print("[NoteAudioEngine] ⚠️ Piano.sf2 not found in bundle!")
        }
    }

    private func warmUp() {
        // Silent note-on/off to prime the audio graph
        try? sampler.play(noteNumber: 60, velocity: 0, channel: 0)
        try? sampler.stop(noteNumber: 60, channel: 0)
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Audio session interrupted — engine is automatically paused
            break
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    try engine.start()
                } catch {
                    print("[NoteAudioEngine] Failed to resume after interruption: \(error)")
                }
            }
        @unknown default:
            break
        }
    }
}
