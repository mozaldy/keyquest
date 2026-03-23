import UIKit
import SwiftUI
import Keyboard
import Tonic

/// Gameplay controller for a single level.
/// Pre-generates all challenge notes, displays them on a paginated staff,
/// and waits for the user to play each one in sequence.
class LevelGameViewController: UIViewController {

    // MARK: - Dependencies

    private let level: Level
    private var audioEngine: NoteAudioEngine!

    // MARK: - UI

    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()
    private let challengeStaff = ChallengeStaffView()
    private var keyboardVC: UIHostingController<AnyView>?

    // MARK: - Game State

    private var challengeNotes: [StaffNote] = []
    private var correctCount: Int = 0
    private var mistakeCount: Int = 0
    private var isWaitingForInput: Bool = false

    // MARK: - Init

    init(level: Level) {
        self.level = level
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Level \(level.id): \(level.title)"
        view.backgroundColor = .systemBackground

        audioEngine = NoteAudioEngine()

        setupUI()
        startLevel()
    }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .bottom }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    // MARK: - Setup

    private func setupUI() {
        // Progress bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = .systemGreen
        progressBar.trackTintColor = .systemGray5
        progressBar.progress = 0
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        view.addSubview(progressBar)

        // Progress label
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        progressLabel.textColor = .secondaryLabel
        progressLabel.textAlignment = .center
        progressLabel.text = "0 / \(level.challengeCount)"
        view.addSubview(progressLabel)

        // Challenge staff
        challengeStaff.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(challengeStaff)

        // Keyboard
        setupKeyboard()

        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Progress bar at top
            progressBar.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            progressBar.heightAnchor.constraint(equalToConstant: 8),

            // Progress label
            progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 4),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Keyboard at bottom, fixed height
            keyboardVC!.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardVC!.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardVC!.view.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            keyboardVC!.view.heightAnchor.constraint(equalToConstant: 220),

            // Staff fills middle
            challengeStaff.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 8),
            challengeStaff.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            challengeStaff.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            challengeStaff.bottomAnchor.constraint(equalTo: keyboardVC!.view.topAnchor, constant: -8)
        ])
    }

    private func setupKeyboard() {
        // Determine the octave range needed for this level's notes
        let octave = level.targetNotes.first?.octave ?? 4
        let startMidi = Int8((octave + 1) * 12)
        let endMidi = Int8(startMidi + 12)

        let keyboardView = KeyboardWrapperForLevel(
            pitchRange: Pitch(startMidi)...Pitch(endMidi),
            onNoteOn: { [weak self] pitch in
                self?.handleKeyPress(pitch: pitch)
            }
        )

        let hc = UIHostingController(rootView: AnyView(keyboardView))
        hc.view.backgroundColor = .clear
        if #available(iOS 16.0, *) {
            hc.sizingOptions = [.preferredContentSize]
        }

        addChild(hc)
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hc.view)
        hc.didMove(toParent: self)

        keyboardVC = hc
    }

    // MARK: - Game Logic

    private func startLevel() {
        // Pre-generate all challenge notes randomly from the level's target notes
        challengeNotes = (0..<level.challengeCount).map { _ in
            level.targetNotes.randomElement()!
        }

        correctCount = 0
        mistakeCount = 0
        isWaitingForInput = true

        // Load all notes onto the staff
        challengeStaff.loadNotes(challengeNotes)
        updateProgress()
    }

    private func handleKeyPress(pitch: Pitch) {
        guard isWaitingForInput,
              let target = challengeStaff.currentTargetNote else { return }

        let midiNote = Int(pitch.midiNoteNumber)

        // Always play the sound
        audioEngine.noteOn(midiNoteNumber: midiNote)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.audioEngine.noteOff(midiNoteNumber: midiNote)
        }

        // Check if correct
        if midiNote == target.midiNoteNumber {
            // Correct!
            isWaitingForInput = false
            correctCount += 1
            challengeStaff.flashCorrect()
            updateProgress()

            // Advance after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }

                if self.correctCount >= self.level.challengeCount {
                    self.completeLevel()
                } else {
                    self.challengeStaff.advanceToNext()
                    self.isWaitingForInput = true
                }
            }
        } else {
            // Incorrect
            mistakeCount += 1
            challengeStaff.flashIncorrect()

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private func updateProgress() {
        let progress = Float(correctCount) / Float(level.challengeCount)
        progressBar.setProgress(progress, animated: true)
        progressLabel.text = "\(correctCount) / \(level.challengeCount)"
    }

    // MARK: - Completion

    private func completeLevel() {
        isWaitingForInput = false

        // Save progress
        LevelProgress.complete(levelId: level.id, mistakes: mistakeCount)

        let stars = LevelProgress.stars(forMistakes: mistakeCount)
        let starsText = String(repeating: "⭐", count: stars)

        let alert = UIAlertController(
            title: "Level Complete! \(starsText)",
            message: "You made \(mistakeCount) mistake\(mistakeCount == 1 ? "" : "s").",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.startLevel()
        })

        alert.addAction(UIAlertAction(title: "Done", style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }
}

// MARK: - Keyboard Wrapper for Level (no octave strip needed)

struct KeyboardWrapperForLevel: View {
    let pitchRange: ClosedRange<Pitch>
    let onNoteOn: (Pitch) -> Void

    var body: some View {
        Keyboard(
            layout: .piano(pitchRange: pitchRange),
            latching: false,
            noteOn: { pitch, _ in onNoteOn(pitch) },
            noteOff: { _ in }
        ) { pitch, isActivated in
            RealisticKeyView(
                pitch: pitch,
                isActivated: isActivated
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
