import SwiftUI
import SwiftTerm

struct TerminalNSViewRepresentable: NSViewRepresentable {
    let session: TerminalSession

    func makeNSView(context: Context) -> NSView {
        let host = NSView()
        host.autoresizesSubviews = true
        attach(to: host)
        return host
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let tv = session.terminalView else { return }
        if tv.superview !== nsView {
            attach(to: nsView)
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: ()) {
        for sub in nsView.subviews {
            sub.removeFromSuperview()
        }
    }

    private func attach(to host: NSView) {
        guard let tv = session.terminalView else { return }
        tv.removeFromSuperview()
        tv.frame = host.bounds
        tv.autoresizingMask = [.width, .height]
        host.addSubview(tv)
    }
}
