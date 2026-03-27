import SwiftUI
import SwiftTerm

struct TerminalNSViewRepresentable: NSViewRepresentable {
    let session: TerminalSession

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
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
        tv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tv)
        NSLayoutConstraint.activate([
            tv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tv.topAnchor.constraint(equalTo: container.topAnchor),
            tv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        // Force layout and redisplay after reparenting to prevent blank terminal
        tv.needsLayout = true
        tv.needsDisplay = true
    }
}
