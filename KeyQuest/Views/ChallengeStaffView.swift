import UIKit

/// Staff view for level gameplay. Displays ALL challenge notes on a grand
/// staff with 6-notes-per-page pagination, just like StaffView in free play.
///
/// Difference from StaffView:
/// - Notes are pre-populated (not added one at a time)
/// - The "current" note is highlighted (filled, colored)
/// - Completed notes are shown in green
/// - Upcoming notes are shown as hollow outlines
/// - Supports correct/incorrect feedback flashes
class ChallengeStaffView: UIView {

    // MARK: - Layout Constants

    private let lineSpacing: CGFloat = 12
    private let noteHeadRadiusX: CGFloat = 8
    private let noteHeadRadiusY: CGFloat = 5.5
    private let leftMargin: CGFloat = 50
    private let notesPerPage = 6
    private let staffGap: CGFloat = 30

    // MARK: - Computed

    private var noteSpacing: CGFloat {
        let available = bounds.width - leftMargin - 20
        guard notesPerPage > 0 else { return 48 }
        return max(35, available / CGFloat(notesPerPage))
    }

    private var trebleCenterY: CGFloat {
        return bounds.midY - staffGap / 2 - 2 * lineSpacing
    }

    private var bassCenterY: CGFloat {
        return bounds.midY + staffGap / 2 + 2 * lineSpacing
    }

    // MARK: - State

    /// All challenge notes for this level.
    private var allNotes: [StaffNote] = []

    /// Index of the note the user currently needs to play. 
    /// Notes before this index are "completed". Notes at/after are upcoming.
    private var currentIndex: Int = 0

    /// Current page (0-based), computed from currentIndex.
    private var currentPage: Int {
        guard !allNotes.isEmpty else { return 0 }
        return currentIndex / notesPerPage
    }

    /// Feedback state for visual flash on the current note.
    enum Feedback { case none, correct, incorrect }
    private var feedback: Feedback = .none

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .systemBackground
        contentMode = .redraw
        isOpaque = true
        clipsToBounds = true
        isAccessibilityElement = true
        accessibilityLabel = "Challenge staff. Press the correct key."
    }

    // MARK: - Public API

    /// Load all challenge notes and reset to the first one.
    func loadNotes(_ notes: [StaffNote]) {
        allNotes = notes
        currentIndex = 0
        feedback = .none
        setNeedsDisplay()
        updateAccessibility()
    }

    /// Advance to the next note (called after a correct answer).
    func advanceToNext() {
        let oldPage = currentPage
        currentIndex += 1
        feedback = .none

        if currentPage != oldPage {
            animatePageTurn()
        } else {
            setNeedsDisplay()
        }
        updateAccessibility()
    }

    /// The note the user currently needs to play, or nil if all done.
    var currentTargetNote: StaffNote? {
        guard currentIndex < allNotes.count else { return nil }
        return allNotes[currentIndex]
    }

    /// Flash green for correct answer.
    func flashCorrect() {
        feedback = .correct
        setNeedsDisplay()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.feedback = .none
            self?.setNeedsDisplay()
        }
    }

    /// Flash red + shake for incorrect answer.
    func flashIncorrect() {
        feedback = .incorrect
        setNeedsDisplay()

        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.35
        animation.values = [-6, 6, -4, 4, -2, 2, 0]
        layer.add(animation, forKey: "shake")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.feedback = .none
            self?.setNeedsDisplay()
        }
    }

    // MARK: - Page Turn Animation

    private func animatePageTurn() {
        if UIAccessibility.isReduceMotionEnabled {
            setNeedsDisplay()
            return
        }
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromRight
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(transition, forKey: "pageTurn")
        setNeedsDisplay()
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let viewBounds = bounds

        // Background
        ctx.setFillColor(UIColor.systemBackground.cgColor)
        ctx.fill(viewBounds)

        // Grand staff
        drawStaffLines(in: ctx, width: viewBounds.width, centerY: trebleCenterY)
        drawTrebleClef(centerY: trebleCenterY)
        drawStaffLines(in: ctx, width: viewBounds.width, centerY: bassCenterY)
        drawBassClef(centerY: bassCenterY)
        drawBarline(in: ctx)

        // Draw notes for the current page
        let page = currentPage
        let startIndex = page * notesPerPage
        let endIndex = min(startIndex + notesPerPage, allNotes.count)

        for i in startIndex..<endIndex {
            let localIndex = i - startIndex
            let note = allNotes[i]

            let noteState: NoteState
            if i < currentIndex {
                noteState = .completed
            } else if i == currentIndex {
                noteState = .current(feedback: feedback)
            } else {
                noteState = .upcoming
            }

            if note.octave >= 5 {
                drawNote(note, at: localIndex, in: ctx,
                         staffCenterY: trebleCenterY, clef: .treble, state: noteState)
            } else {
                drawNote(note, at: localIndex, in: ctx,
                         staffCenterY: bassCenterY, clef: .bass, state: noteState)
            }
        }
    }

    // MARK: - Note States

    private enum NoteState {
        case completed                       // Already answered correctly (green ✓)
        case current(feedback: Feedback)     // Active challenge (highlighted)
        case upcoming                        // Not yet reached (hollow outline)
    }

    private enum Clef { case treble, bass }

    // MARK: - Staff Lines

    private func drawStaffLines(in ctx: CGContext, width: CGFloat, centerY: CGFloat) {
        ctx.setStrokeColor(UIColor.label.cgColor)
        ctx.setLineWidth(1.0)
        for offset in -2...2 {
            let y = centerY + CGFloat(offset) * lineSpacing
            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: width, y: y))
        }
        ctx.strokePath()
    }

    private func drawBarline(in ctx: CGContext) {
        let topY = trebleCenterY - 2 * lineSpacing
        let bottomY = bassCenterY + 2 * lineSpacing
        ctx.setStrokeColor(UIColor.label.cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: 0.75, y: topY))
        ctx.addLine(to: CGPoint(x: 0.75, y: bottomY))
        ctx.strokePath()
    }

    // MARK: - Clefs

    private func drawTrebleClef(centerY: CGFloat) {
        let clefString = "\u{1D11E}"
        let scaledSize = UIFontMetrics(forTextStyle: .title1).scaledValue(for: 42)
        let font = UIFont.systemFont(ofSize: scaledSize)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
        let str = NSAttributedString(string: clefString, attributes: attrs)
        let size = str.size()
        str.draw(at: CGPoint(x: 4, y: centerY + lineSpacing - size.height * 0.52))
    }

    private func drawBassClef(centerY: CGFloat) {
        let clefString = "\u{1D122}"
        let scaledSize = UIFontMetrics(forTextStyle: .title1).scaledValue(for: 34)
        let font = UIFont.systemFont(ofSize: scaledSize)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
        let str = NSAttributedString(string: clefString, attributes: attrs)
        let size = str.size()
        str.draw(at: CGPoint(x: 6, y: centerY - size.height * 0.38))
    }

    // MARK: - Note Rendering

    private func drawNote(_ note: StaffNote, at localIndex: Int, in ctx: CGContext,
                           staffCenterY: CGFloat, clef: Clef, state: NoteState) {
        let noteX = leftMargin + CGFloat(localIndex) * noteSpacing

        let noteY: CGFloat
        switch clef {
        case .treble:
            let steps = (6 - note.pitchClass.staffStep) + (4 - note.octave) * 7
            noteY = staffCenterY + CGFloat(steps) * (lineSpacing / 2)
        case .bass:
            let steps = (1 - note.pitchClass.staffStep) + (3 - note.octave) * 7
            noteY = staffCenterY + CGFloat(steps) * (lineSpacing / 2)
        }

        // Ledger lines
        drawLedgerLines(noteX: noteX, noteY: noteY, staffCenterY: staffCenterY, in: ctx)

        // Note head
        let noteRect = CGRect(
            x: noteX - noteHeadRadiusX,
            y: noteY - noteHeadRadiusY,
            width: noteHeadRadiusX * 2,
            height: noteHeadRadiusY * 2
        )

        switch state {
        case .completed:
            // Green filled note with checkmark feel
            ctx.setFillColor(UIColor.systemGreen.cgColor)
            ctx.fillEllipse(in: noteRect)

        case .current(let fb):
            // Highlighted current note — filled, with feedback color
            let color: UIColor
            switch fb {
            case .none: color = .systemBlue
            case .correct: color = .systemGreen
            case .incorrect: color = .systemRed
            }
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: noteRect)
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(2.5)
            ctx.strokeEllipse(in: noteRect)

        case .upcoming:
            // Hollow outline
            ctx.setStrokeColor(UIColor.tertiaryLabel.cgColor)
            ctx.setLineWidth(1.5)
            ctx.strokeEllipse(in: noteRect)
        }

        // Accidental
        if note.pitchClass.isAccidental {
            let labelColor: UIColor
            switch state {
            case .completed: labelColor = .systemGreen
            case .current: labelColor = .systemBlue
            case .upcoming: labelColor = .tertiaryLabel
            }
            drawSharp(noteX: noteX, noteY: noteY, color: labelColor)
        }

        // Note name label (only for completed notes as a teaching aid)
        if case .completed = state {
            drawNoteLabel(note: note, noteX: noteX, noteY: noteY, color: .systemGreen)
        }
    }

    // MARK: - Ledger Lines

    private func drawLedgerLines(noteX: CGFloat, noteY: CGFloat, staffCenterY: CGFloat, in ctx: CGContext) {
        let topLine = staffCenterY - 2 * lineSpacing
        let bottomLine = staffCenterY + 2 * lineSpacing
        let ext: CGFloat = noteHeadRadiusX + 3

        ctx.setStrokeColor(UIColor.label.cgColor)
        ctx.setLineWidth(1.0)

        if noteY > bottomLine + lineSpacing / 2 {
            var y = bottomLine + lineSpacing
            while y <= noteY + lineSpacing / 4 {
                ctx.move(to: CGPoint(x: noteX - ext, y: y))
                ctx.addLine(to: CGPoint(x: noteX + ext, y: y))
                y += lineSpacing
            }
            ctx.strokePath()
        }

        if noteY < topLine - lineSpacing / 2 {
            var y = topLine - lineSpacing
            while y >= noteY - lineSpacing / 4 {
                ctx.move(to: CGPoint(x: noteX - ext, y: y))
                ctx.addLine(to: CGPoint(x: noteX + ext, y: y))
                y -= lineSpacing
            }
            ctx.strokePath()
        }
    }

    // MARK: - Sharp & Labels

    private func drawSharp(noteX: CGFloat, noteY: CGFloat, color: UIColor) {
        let font = UIFont.systemFont(ofSize: 11)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let str = NSAttributedString(string: "♯", attributes: attrs)
        let size = str.size()
        str.draw(at: CGPoint(x: noteX - noteHeadRadiusX - 9 - size.width / 2, y: noteY - size.height / 2 + 1))
    }

    private func drawNoteLabel(note: StaffNote, noteX: CGFloat, noteY: CGFloat, color: UIColor) {
        let name = "\(note.pitchClass.displayName)\(note.octave)"
        let font = UIFont.preferredFont(forTextStyle: .caption2)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let str = NSAttributedString(string: name, attributes: attrs)
        let size = str.size()
        str.draw(at: CGPoint(x: noteX - size.width / 2, y: noteY + noteHeadRadiusY + 6))
    }

    // MARK: - Accessibility

    private func updateAccessibility() {
        if let note = currentTargetNote {
            accessibilityLabel = "Challenge \(currentIndex + 1) of \(allNotes.count). Play \(note.pitchClass.displayName)\(note.octave)."
        } else {
            accessibilityLabel = "All challenges completed."
        }
    }
}
