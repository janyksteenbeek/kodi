import SwiftUI
import SwiftTerm
import UserNotifications

@Observable
final class TerminalSession: Identifiable {
    let id: UUID
    var title: String
    let workingDirectory: URL
    var isRunning: Bool = true
    let createdAt: Date

    var program: TerminalProgram = .shell
    var activityState: TerminalActivityState = .idle

    private(set) var terminalView: LocalProcessTerminalView?
    private var delegateHandler: TerminalDelegateHandler?
    private var activityTimer: Timer?
    private var loadingTimer: Timer?

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

    func startProcess(initialCommand: String, program: TerminalProgram = .shell) {
        self.program = program
        if program != .shell {
            self.activityState = .loading
            // Stay in loading for a fixed period — shell output during startup is noise
            loadingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, self.activityState == .loading else { return }
                    self.activityState = .idle
                }
            }
        }
        startProcess()
        guard !initialCommand.isEmpty, let tv = terminalView else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let cmdBytes = Array((initialCommand + "\n").utf8)
            tv.send(cmdBytes)
        }
    }

    private var isTrackingEnabled: Bool {
        UserDefaults.standard.object(forKey: "terminalActivityTracking") as? Bool ?? true
    }

    func markActivity() {
        guard program != .shell, isTrackingEnabled else { return }
        if activityState == .loading { return }
        activityState = .busy
        resetActivityTimer()
    }

    func markTitleChanged() {
        guard program != .shell, isTrackingEnabled else { return }
        if activityState == .loading {
            loadingTimer?.invalidate()
            loadingTimer = nil
            activityState = .busy
            resetActivityTimer()
        } else {
            activityState = .busy
            resetActivityTimer()
        }
    }

    private func resetActivityTimer() {
        activityTimer?.invalidate()
        let timeout = UserDefaults.standard.object(forKey: "terminalIdleTimeout") as? Double ?? 2.0
        activityTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.activityState == .busy else { return }
                self.activityState = .idle
            }
        }
    }

    func terminate() {
        isRunning = false
        activityTimer?.invalidate()
        activityTimer = nil
        loadingTimer?.invalidate()
        loadingTimer = nil
        terminalView?.send([0x04])
        terminalView = nil
        delegateHandler = nil
    }

    deinit {
        activityTimer?.invalidate()
        loadingTimer?.invalidate()
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
            guard let session else { return }
            if !title.isEmpty {
                session.title = title
            }
            session.markTitleChanged()
        }
    }

    nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        MainActor.assumeIsolated {
            session?.markActivity()
        }
    }

    nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {
        MainActor.assumeIsolated {
            guard let session else { return }
            session.isRunning = false
            session.activityState = .idle

            if session.program != .shell {
                let notify = UserDefaults.standard.object(forKey: "aiNotifyOnComplete") as? Bool ?? false
                if notify {
                    let content = UNMutableNotificationContent()
                    content.title = "\(session.program.displayName) Finished"
                    content.body = "\(session.title) has completed."
                    content.sound = .default
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }
}
