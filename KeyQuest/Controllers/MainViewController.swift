import UIKit

/// Root view controller. Creates all shared dependencies, sets up the view hierarchy,
/// and wires everything together.
class MainViewController: UIViewController {

    // MARK: - Dependencies

    private var scoreViewModel: ScoreViewModel!
    private var audioEngine: NoteAudioEngine!

    // MARK: - Views

    private var staffView: StaffView!
    private var clearButton: UIButton!
    private var keyboardVC: KeyboardViewController!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // 1. Create dependencies in correct order
        scoreViewModel = ScoreViewModel()
        audioEngine = NoteAudioEngine()

        // 2. Create StaffView and bind
        staffView = StaffView()
        staffView.translatesAutoresizingMaskIntoConstraints = false
        staffView.bind(to: scoreViewModel)
        view.addSubview(staffView)

        // 3. Create Clear button
        clearButton = createClearButton()
        view.addSubview(clearButton)

        // 4. Create KeyboardViewController
        keyboardVC = KeyboardViewController()
        keyboardVC.audioEngine = audioEngine
        keyboardVC.scoreViewModel = scoreViewModel

        addChild(keyboardVC)
        keyboardVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardVC.view)
        keyboardVC.didMove(toParent: self)

        // 5. Layout
        setupConstraints()

        // 6. Accessibility navigation order
        view.accessibilityElements = [staffView!, clearButton!, keyboardVC.view!]

        // 7. Restore previous session
        restoreState()
    }

    // MARK: - System Gesture Overrides

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        .bottom
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    // MARK: - Layout

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Keyboard: fixed height, pinned to bottom of safe area
            keyboardVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardVC.view.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            keyboardVC.view.heightAnchor.constraint(equalToConstant: 260),

            // Clear button: just above keyboard
            clearButton.bottomAnchor.constraint(equalTo: keyboardVC.view.topAnchor, constant: -4),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            clearButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            clearButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),

            // StaffView: fills everything from top to clear button
            staffView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            staffView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            staffView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            staffView.bottomAnchor.constraint(equalTo: clearButton.topAnchor, constant: -4)
        ])
    }

    // MARK: - Clear Button

    private func createClearButton() -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = "Clear"
        config.baseForegroundColor = .systemRed

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false

        // Accessibility
        button.accessibilityLabel = "Clear all notes"
        button.accessibilityHint = "Removes all notes from the staff."

        button.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        return button
    }

    @objc private func clearTapped() {
        scoreViewModel.clear()
    }

    // MARK: - State Restoration

    private static let savedNotesKey = "savedNotes"

    private func restoreState() {
        guard let savedPairs = UserDefaults.standard.array(forKey: Self.savedNotesKey) as? [[Int]] else {
            return
        }
        for pair in savedPairs {
            guard pair.count == 2,
                  let pitchClass = PitchClass(rawValue: pair[0]) else { continue }
            scoreViewModel.append(pitchClass: pitchClass, octave: pair[1])
        }
    }

    /// Call this when saving state (from SceneDelegate on background entry).
    func saveState() {
        let pairs = scoreViewModel.notes.map { [$0.pitchClass.rawValue, $0.octave] }
        UserDefaults.standard.set(pairs, forKey: Self.savedNotesKey)
    }

    /// Access to the audio engine for lifecycle management.
    func getAudioEngine() -> NoteAudioEngine {
        return audioEngine
    }
}
