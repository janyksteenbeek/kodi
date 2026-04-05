import SwiftUI
import AppKit

@Observable
final class EditorSession: Identifiable {
    let id: UUID
    let relativePath: String
    var content: String
    var hasUnsavedChanges: Bool = false
    let repositoryPath: URL

    private(set) var scrollView: NSScrollView?
    private(set) var textView: NSTextView?
    private var coordinator: EditorCoordinator?

    var fileName: String {
        URL(fileURLWithPath: relativePath).lastPathComponent
    }

    var fileExtension: String {
        URL(fileURLWithPath: relativePath).pathExtension
    }

    init(id: UUID = UUID(), relativePath: String, content: String, repositoryPath: URL) {
        self.id = id
        self.relativePath = relativePath
        self.content = content
        self.repositoryPath = repositoryPath
    }

    func setUp(font: NSFont) {
        let scrollView = NSScrollView()
        let textView = NSTextView()

        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.font = font
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .labelColor
        textView.textContainerInset = NSSize(width: 8, height: 8)

        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        let coordinator = EditorCoordinator(session: self)
        textView.delegate = coordinator
        self.coordinator = coordinator

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let rulerView = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = rulerView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        textView.string = content
        coordinator.applySyntaxHighlighting()

        self.scrollView = scrollView
        self.textView = textView
    }

    func save() {
        let fullURL = repositoryPath.appendingPathComponent(relativePath)
        do {
            try content.write(to: fullURL, atomically: true, encoding: .utf8)
            hasUnsavedChanges = false
        } catch {
            // Error handled by caller
        }
    }

    func updateFont(_ font: NSFont) {
        textView?.font = font
        coordinator?.applySyntaxHighlighting()
    }

    func tearDown() {
        textView?.delegate = nil
        scrollView?.documentView = nil
        scrollView = nil
        textView = nil
        coordinator = nil
    }
}

// MARK: - Editor Coordinator

private class EditorCoordinator: NSObject, NSTextViewDelegate {
    private weak var session: EditorSession?
    private var highlightWorkItem: DispatchWorkItem?

    init(session: EditorSession) {
        self.session = session
    }

    func textDidChange(_ notification: Notification) {
        guard let session, let textView = session.textView else { return }
        session.content = textView.string
        session.hasUnsavedChanges = true

        highlightWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                self?.applySyntaxHighlighting()
            }
        }
        highlightWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    func applySyntaxHighlighting() {
        guard let session, let textView = session.textView,
              let textStorage = textView.textStorage else { return }
        let font = textView.font ?? .monospacedSystemFont(ofSize: 12, weight: .regular)
        let highlighted = SyntaxHighlighter.highlightNS(
            textView.string,
            fileExtension: session.fileExtension,
            font: font
        )

        let selectedRanges = textView.selectedRanges
        textStorage.beginEditing()
        textStorage.setAttributedString(highlighted)
        textStorage.endEditing()
        textView.selectedRanges = selectedRanges

        (textView.enclosingScrollView?.verticalRulerView as? LineNumberRulerView)?.needsDisplay = true
    }
}

// MARK: - Line Number Ruler

class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView!, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 40

        NotificationCenter.default.addObserver(
            self, selector: #selector(textDidChange),
            name: NSText.didChangeNotification, object: textView
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(textDidChange),
            name: NSView.frameDidChangeNotification, object: textView
        )
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }

    @objc private func textDidChange(_ notification: Notification) {
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView, let layoutManager = textView.layoutManager else { return }

        let visibleRect = scrollView?.contentView.bounds ?? .zero
        let text = textView.string as NSString
        let inset = textView.textContainerInset.height

        guard text.length > 0 else { return }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]

        var lineNumber = 1
        var charIndex = 0

        while charIndex < text.length {
            let lineRange = text.lineRange(for: NSRange(location: charIndex, length: 0))
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: charIndex)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            let y = lineRect.origin.y + inset - visibleRect.origin.y

            if y + lineRect.height >= 0, y <= visibleRect.height {
                let string = "\(lineNumber)" as NSString
                let size = string.size(withAttributes: attrs)
                let point = NSPoint(
                    x: ruleThickness - size.width - 8,
                    y: y + (lineRect.height - size.height) / 2
                )
                string.draw(at: point, withAttributes: attrs)
            }

            if y > visibleRect.height { break }

            charIndex = NSMaxRange(lineRange)
            lineNumber += 1
        }
    }
}
