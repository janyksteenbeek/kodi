import SwiftUI
import SwiftTerm

struct TerminalNSViewRepresentable: NSViewRepresentable {
    let session: TerminalSession

    func makeNSView(context: Context) -> NSView {
        guard let container = session.containerView else { return NSView() }
        // The container lives on the session for its whole lifetime. If SwiftUI
        // hasn't dismantled a previous host yet (e.g. tab → panel move), detach
        // before reattaching to avoid the "view already has a superview" assert.
        container.removeFromSuperview()
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No-op. The container is stable across renders — moving it would
        // force AppKit to invalidate SwiftTerm's layer-backed contents, which
        // is exactly the "replay the scrollback" symptom we want to avoid.
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: ()) {
        nsView.removeFromSuperview()
    }
}

/// Container that suppresses terminal resizing only during native NSWindow
/// live-resize (window edge drag), where SwiftTerm's per-frame reflow is
/// genuinely jittery. Everything else — SwiftUI layout updates, SplitDivider
/// drag, initial sizing — must propagate immediately so SwiftTerm's grid
/// (and the SIGWINCH it sends to the child process) stays in sync with the
/// visible area. Delaying that breaks TUI apps like claude-code.
final class TerminalResizeContainerView: NSView {
    private var isLiveResizing = false

    override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        isLiveResizing = true
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        isLiveResizing = false
        applyBoundsToChildren()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if isLiveResizing { return }
        applyBoundsToChildren()
    }

    private func applyBoundsToChildren() {
        for sub in subviews where sub.frame != bounds {
            sub.frame = bounds
        }
    }
}
