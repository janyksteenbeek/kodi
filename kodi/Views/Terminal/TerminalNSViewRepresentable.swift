import SwiftUI
import SwiftTerm

struct TerminalNSViewRepresentable: NSViewRepresentable {
    let session: TerminalSession

    func makeNSView(context: Context) -> NSView {
        let container = TerminalResizeContainerView()
        attachTerminalView(to: container)
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let tv = session.terminalView else { return }

        // Already correctly attached — nothing to do
        if tv.superview == nsView { return }

        // Remove all old subviews (previous terminal that was swapped out)
        for subview in nsView.subviews {
            subview.removeFromSuperview()
        }

        attachTerminalView(to: nsView)
    }

    private func attachTerminalView(to container: NSView) {
        guard let tv = session.terminalView else { return }

        // Remove from any previous container (terminal can only be in one place)
        tv.removeFromSuperview()
        // Use manual layout (no auto-layout constraints) so the container can
        // choose when to propagate size changes to the terminal — SwiftTerm
        // reflows its grid on every frame change, which makes text jump around
        // mid-drag.
        tv.translatesAutoresizingMaskIntoConstraints = true
        tv.autoresizingMask = []
        tv.frame = container.bounds
        container.addSubview(tv)

        tv.needsLayout = true
        tv.needsDisplay = true
    }
}

/// Container that freezes terminal resizing during live/interactive drags.
/// SwiftTerm reflows its grid on every frame change, causing visible text
/// jitter. The child has no autoresizing mask — we explicitly set its frame
/// only when we want the terminal to reflow (drag end, or debounced after
/// programmatic size changes settle).
final class TerminalResizeContainerView: NSView {
    private var isLiveResizing = false
    private var pendingResizeWorkItem: DispatchWorkItem?

    override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        isLiveResizing = true
        pendingResizeWorkItem?.cancel()
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        isLiveResizing = false
        applyBoundsToChildren()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if isLiveResizing { return }
        scheduleDebouncedApply()
    }

    private func applyBoundsToChildren() {
        for sub in subviews where sub.frame != bounds {
            sub.frame = bounds
        }
    }

    private func scheduleDebouncedApply() {
        pendingResizeWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self, !self.isLiveResizing else { return }
            self.applyBoundsToChildren()
        }
        pendingResizeWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: item)
    }
}
