import SwiftUI
import SwiftTerm

@Observable
final class TerminalSession: Identifiable {
    let id: UUID
    var title: String
    let workingDirectory: URL
    var isRunning: Bool = true
    let createdAt: Date

    private(set) var terminalView: LocalProcessTerminalView?
    private var delegateHandler: TerminalDelegateHandler?

    init(id: UUID = UUID(), title: String, workingDirectory: URL) {
        self.id = id
        self.title = title
        self.workingDirectory = workingDirectory
        self.createdAt = Date()
    }

    func startProcess() {
        let tv = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))

        let fontSize = UserDefaults.standard.double(forKey: "terminalFontSize")
        tv.font = NSFont.monospacedSystemFont(ofSize: fontSize > 0 ? fontSize : 13, weight: .regular)

        let handler = TerminalDelegateHandler(session: self)
        tv.processDelegate = handler
        self.delegateHandler = handler

        let customShell = UserDefaults.standard.string(forKey: "terminalShell") ?? ""
        let shell = customShell.isEmpty
            ? (ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh")
            : customShell

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["LANG"] = env["LANG"] ?? "en_US.UTF-8"
        let envArray = env.map { "\($0.key)=\($0.value)" }

        tv.startProcess(
            executable: shell,
            args: [],
            environment: envArray,
            execName: nil,
            currentDirectory: workingDirectory.path
        )

        self.terminalView = tv
    }

    func startProcess(initialCommand: String) {
        startProcess()
        guard !initialCommand.isEmpty, let tv = terminalView else { return }
        // Send the command after a brief delay to let the shell initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let cmdBytes = Array((initialCommand + "\n").utf8)
            tv.send(cmdBytes)
        }
    }

    func terminate() {
        isRunning = false
        terminalView?.send([0x04]) // Ctrl+D to gracefully close
        terminalView = nil
        delegateHandler = nil
    }

    deinit {
        if isRunning {
            terminalView = nil
            delegateHandler = nil
        }
    }
}

private class TerminalDelegateHandler: NSObject, LocalProcessTerminalViewDelegate {
    weak var session: TerminalSession?

    init(session: TerminalSession) {
        self.session = session
    }

    nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
    }

    nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        MainActor.assumeIsolated {
            session?.title = title.isEmpty ? session?.title ?? "Terminal" : title
        }
    }

    nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
    }

    nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {
        MainActor.assumeIsolated {
            session?.isRunning = false
        }
    }
}
