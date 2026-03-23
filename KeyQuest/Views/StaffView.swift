import UIKit
import Combine

/// Displays a grand staff (treble + bass clef) with notes.
///
/// **Routing rule:** octave ≥ 5 → treble clef, octave ≤ 4 → bass clef.
///
/// **Architecture:** plain UIView overriding `draw(_:)`. Two 5-line staves
/// drawn at fixed vertical positions. Notes are placed on the correct
/// staff based on their octave. 6 notes per page, page-turn animation.
class StaffView: UIView {

    // MARK: - Layout Constants

    private let lineSpacing: CGFloat = 12
    private let noteHeadRadiusX: CGFloat = 8
    private let noteHeadRadiusY: CGFloat = 5.5
    private let leftMargin: CGFloat = 50
    private let notesPerPage = 6
    private let showNoteNameLabels = true

    /// Gap between the bottom of treble staff and top of bass staff.
    private let staffGap: CGFloat = 30

    // MARK: - Computed

    private var noteSpacing: CGFloat {
        let available = bounds.width - leftMargin - 20
        guard notesPerPage > 0 else { return 48 }
        return max(35, available / CGFloat(notesPerPage))
    }

    /// Center Y of the treble staff (3rd line = B4).
    private var trebleCenterY: CGFloat {
        let totalStaffHeight = 4 * lineSpacing * 2 + staffGap
        return bounds.midY - staffGap / 2 - 2 * lineSpacing
    }

    /// Center Y of the bass staff (3rd line = D3).
    private var bassCenterY: CGFloat {
        return bounds.midY + staffGap / 2 + 2 * lineSpacing
    }

    // MARK: - State

    private var allNotes: [StaffNote] = []
    private var currentPage: Int = 0
    private var cancellables = Set<AnyCancellable>()

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
        accessibilityLabel = "Sheet music. No notes."
        accessibilityHint = "Press piano keys to add notes."
    }

    // MARK: - Public

    func bind(to viewModel: ScoreViewModel) {
        viewModel.$notes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notes in
                self?.handleNotesUpdate(notes)
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Updates

    private func handleNotesUpdate(_ notes: [StaffNote]) {
        let oldPage = currentPage
        allNotes = notes

        if notes.isEmpty {
            currentPage = 0
            setNeedsDisplay()
            updateAccessibilityLabel()
            return
        }

        let targetPage = (notes.count - 1) / notesPerPage
        if targetPage != oldPage {
            currentPage = targetPage
            animatePageTurn()
        } else {
            setNeedsDisplay()
        }
        updateAccessibilityLabel()
    }

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

        // --- Grand Staff ---
        // Treble staff
        drawStaffLines(in: ctx, width: viewBounds.width, centerY: trebleCenterY)
        drawTrebleClef(centerY: trebleCenterY)

        // Bass staff
        drawStaffLines(in: ctx, width: viewBounds.width, centerY: bassCenterY)
        drawBassClef(centerY: bassCenterY)

        // Brace / barline connecting the two staves at the left
        drawGrandStaffBarline(in: ctx)

        // --- Notes for current page ---
        let startIndex = currentPage * notesPerPage
        let endIndex = min(startIndex + notesPerPage, allNotes.count)

        for i in startIndex..<endIndex {
            let localIndex = i - startIndex
            let note = allNotes[i]

            if note.octave >= 5 {
                drawNote(note, at: localIndex, in: ctx,
                         staffCenterY: trebleCenterY, clef: .treble)
            } else {
                drawNote(note, at: localIndex, in: ctx,
                         staffCenterY: bassCenterY, clef: .bass)
            }
        }
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

    // MARK: - Grand Staff Barline

    private func drawGrandStaffBarline(in ctx: CGContext) {
        let topY = trebleCenterY - 2 * lineSpacing
        let bottomY = bassCenterY + 2 * lineSpacing

        ctx.setStrokeColor(UIColor.label.cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: 0.75, y: topY))
        ctx.addLine(to: CGPoint(x: 0.75, y: bottomY))
        ctx.strokePath()
    }

    // MARK: - Treble Clef

    private func drawTrebleClef(centerY: CGFloat) {
        let clefString = "\u{1D11E}"

        let metrics = UIFontMetrics(forTextStyle: .title1)
        let scaledSize = metrics.scaledValue(for: 42)
        let font = UIFont.systemFont(ofSize: scaledSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]

        let attrString = NSAttributedString(string: clefString, attributes: attributes)
        let size = attrString.size()

        let x: CGFloat = 4
        let y = centerY + lineSpacing - size.height * 0.52

        attrString.draw(at: CGPoint(x: x, y: y))
    }

    // MARK: - Bass Clef

    private func drawBassClef(centerY: CGFloat) {
        let clefString = "\u{1D122}"

        let metrics = UIFontMetrics(forTextStyle: .title1)
        let scaledSize = metrics.scaledValue(for: 34)
        let font = UIFont.systemFont(ofSize: scaledSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]

        let attrString = NSAttributedString(string: clefString, attributes: attributes)
        let size = attrString.size()

        let x: CGFloat = 6
        // Position so the two dots straddle the D3 line (center)
        let y = centerY - size.height * 0.38

        attrString.draw(at: CGPoint(x: x, y: y))
    }

    // MARK: - Note Rendering

    private func drawNote(_ note: StaffNote, at localIndex: Int, in ctx: CGContext,
                           staffCenterY: CGFloat, clef: Clef) {
        let noteX = leftMargin + CGFloat(localIndex) * noteSpacing

        let noteY: CGFloat
        switch clef {
        case .treble:
            // B4 is at trebleCenterY. Each diatonic step = lineSpacing/2.
            let stepsFromB4 = (6 - note.pitchClass.staffStep) + (4 - note.octave) * 7
            noteY = staffCenterY + CGFloat(stepsFromB4) * (lineSpacing / 2)
        case .bass:
            // D3 is at bassCenterY. Each diatonic step = lineSpacing/2.
            let stepsFromD3 = (1 - note.pitchClass.staffStep) + (3 - note.octave) * 7
            noteY = staffCenterY + CGFloat(stepsFromD3) * (lineSpacing / 2)
        }

        // Ledger lines
        drawLedgerLines(noteX: noteX, noteY: noteY, staffCenterY: staffCenterY, in: ctx)

        // Whole note head (stroked/unfilled ellipse)
        let noteRect = CGRect(
            x: noteX - noteHeadRadiusX,
            y: noteY - noteHeadRadiusY,
            width: noteHeadRadiusX * 2,
            height: noteHeadRadiusY * 2
        )
        ctx.setStrokeColor(UIColor.label.cgColor)
        ctx.setLineWidth(1.8)
        ctx.strokeEllipse(in: noteRect)

        // Accidental symbol
        if note.pitchClass.isAccidental {
            drawSharpSymbol(noteX: noteX, noteY: noteY)
        }

        // Note name label
        if showNoteNameLabels {
            drawNoteNameLabel(note: note, noteX: noteX, noteY: noteY)
        }
    }

    // MARK: - Ledger Lines

    private func drawLedgerLines(noteX: CGFloat, noteY: CGFloat, staffCenterY: CGFloat, in ctx: CGContext) {
        let topLine = staffCenterY - 2 * lineSpacing
        let bottomLine = staffCenterY + 2 * lineSpacing
        let ext: CGFloat = noteHeadRadiusX + 3

        ctx.setStrokeColor(UIColor.label.cgColor)
        ctx.setLineWidth(1.0)

        // Ledger lines below the staff
        if noteY > bottomLine + lineSpacing / 2 {
            var ledgerY = bottomLine + lineSpacing
            while ledgerY <= noteY + lineSpacing / 4 {
                ctx.move(to: CGPoint(x: noteX - ext, y: ledgerY))
                ctx.addLine(to: CGPoint(x: noteX + ext, y: ledgerY))
                ledgerY += lineSpacing
            }
            ctx.strokePath()
        }

        // Ledger lines above the staff
        if noteY < topLine - lineSpacing / 2 {
            var ledgerY = topLine - lineSpacing
            while ledgerY >= noteY - lineSpacing / 4 {
                ctx.move(to: CGPoint(x: noteX - ext, y: ledgerY))
                ctx.addLine(to: CGPoint(x: noteX + ext, y: ledgerY))
                ledgerY -= lineSpacing
            }
            ctx.strokePath()
        }
    }

    // MARK: - Sharp Symbol

    private func drawSharpSymbol(noteX: CGFloat, noteY: CGFloat) {
        let sharpString = "♯"

        let metrics = UIFontMetrics(forTextStyle: .caption1)
        let scaledSize = metrics.scaledValue(for: 11)
        let font = UIFont.systemFont(ofSize: scaledSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]

        let attrString = NSAttributedString(string: sharpString, attributes: attributes)
        let size = attrString.size()

        let x = noteX - noteHeadRadiusX - 9 - size.width / 2
        let y = noteY - size.height / 2 + 1

        attrString.draw(at: CGPoint(x: x, y: y))
    }

    // MARK: - Note Name Label

    private func drawNoteNameLabel(note: StaffNote, noteX: CGFloat, noteY: CGFloat) {
        let name = "\(note.pitchClass.displayName)\(note.octave)"

        let font = UIFont.preferredFont(forTextStyle: .caption2)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.secondaryLabel
        ]

        let attrString = NSAttributedString(string: name, attributes: attributes)
        let size = attrString.size()

        let x = noteX - size.width / 2
        let y = noteY + noteHeadRadiusY + 8

        attrString.draw(at: CGPoint(x: x, y: y))
    }

    // MARK: - Accessibility

    private func updateAccessibilityLabel() {
        if allNotes.isEmpty {
            accessibilityLabel = "Sheet music. No notes."
        } else {
            let noteNames = allNotes.map { "\($0.pitchClass.displayName)\($0.octave)" }
            accessibilityLabel = "Sheet music. \(allNotes.count) notes: \(noteNames.joined(separator: ", "))."
        }
    }
}
