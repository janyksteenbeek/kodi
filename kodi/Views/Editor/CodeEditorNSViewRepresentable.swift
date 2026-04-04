import SwiftUI
import AppKit

struct CodeEditorNSViewRepresentable: NSViewRepresentable {
    @Binding var text: String
    let fileExtension: String
    let font: NSFont
    var onTextChange: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
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

        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        // Line numbers
        let rulerView = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = rulerView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        // Set initial content and highlight
        textView.string = text
        context.coordinator.applySyntaxHighlighting()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Only update text if it changed externally (not from typing)
        if !context.coordinator.isUpdating && textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.applySyntaxHighlighting()
        }

        if textView.font != font {
            textView.font = font
            context.coordinator.applySyntaxHighlighting()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditorNSViewRepresentable
        weak var textView: NSTextView?
        var isUpdating = false
        private var highlightWorkItem: DispatchWorkItem?

        init(_ parent: CodeEditorNSViewRepresentable) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            isUpdating = true
            parent.text = textView.string
            parent.onTextChange()
            isUpdating = false

            // Debounced syntax highlighting
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
            guard let textView, let textStorage = textView.textStorage else { return }
            let code = textView.string
            let highlighted = SyntaxHighlighter.highlightNS(code, fileExtension: parent.fileExtension, font: parent.font)

            textStorage.beginEditing()
            textStorage.setAttributedString(highlighted)
            textStorage.endEditing()

            // Notify ruler to update line numbers
            (textView.enclosingScrollView?.verticalRulerView as? LineNumberRulerView)?.needsDisplay = true
        }
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
