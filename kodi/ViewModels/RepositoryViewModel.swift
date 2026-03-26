import SwiftUI

@Observable
final class RepositoryViewModel: Identifiable {
    let id: UUID
    let repository: GitRepository

    var changedFiles: [ChangedFile] = []
    var selectedFilePath: String?
    var currentDiff: [DiffResult] = []
    var commitMessage: String = ""
    var isLoading: Bool = false
    var isSyncing: Bool = false
    var error: String?
    var diffMode: DiffMode
    var hasRemote: Bool = false
    var commitsAhead: Int = 0
    var commitsBehind: Int = 0

    var terminalSessions: [TerminalSession] = []
    private var terminalCounter: Int = 0
    var isTerminalPanelVisible: Bool = false
    var terminalPanelMode: TerminalPanelMode
    var panelTerminalID: UUID?

    private let gitService: GitService

    enum DiffMode: String, CaseIterable {
        case unified = "Unified"
        case sideBySide = "Side by Side"

        var icon: String {
            switch self {
            case .unified: "text.alignleft"
            case .sideBySide: "rectangle.split.2x1"
            }
        }
    }

    enum TerminalPanelMode: String, CaseIterable {
        case bottom = "Bottom"
        case right = "Right"

        var icon: String {
            switch self {
            case .bottom: "rectangle.split.1x2"
            case .right: "rectangle.split.2x1"
            }
        }
    }

    init(repository: GitRepository, gitService: GitService) {
        self.id = repository.id
        self.repository = repository
        self.gitService = gitService

        let savedDiffMode = UserDefaults.standard.string(forKey: "defaultDiffMode") ?? "unified"
        self.diffMode = DiffMode(rawValue: savedDiffMode == "sideBySide" ? "Side by Side" : "Unified") ?? .unified

        let savedPanelMode = UserDefaults.standard.string(forKey: "defaultTerminalPanelMode") ?? "bottom"
        self.terminalPanelMode = TerminalPanelMode(rawValue: savedPanelMode == "right" ? "Right" : "Bottom") ?? .bottom
    }

    var stagedFiles: [ChangedFile] {
        changedFiles.filter(\.isStaged)
    }

    var stagedCount: Int {
        stagedFiles.count
    }

    var selectedFile: ChangedFile? {
        changedFiles.first { $0.path == selectedFilePath }
    }

    func refresh() async {
        isLoading = true
        error = nil
        do {
            changedFiles = try await gitService.status(at: repository.path)
            if let path = selectedFilePath {
                if changedFiles.contains(where: { $0.path == path }) {
                    await loadDiff(for: path)
                } else {
                    selectedFilePath = nil
                    await loadAllDiffs()
                }
            } else {
                await loadAllDiffs()
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
        await refreshRemoteStatus()
    }

    private func loadAllDiffs() async {
        var allDiffs: [DiffResult] = []
        for file in changedFiles {
            do {
                let rawDiff: String
                if file.status == .untracked {
                    rawDiff = try await gitService.diffUntrackedFile(at: repository.path, file: file.path)
                } else {
                    rawDiff = try await gitService.diffForFile(at: repository.path, file: file.path, staged: file.isStaged)
                }
                allDiffs.append(contentsOf: DiffParser.parse(rawDiff))
            } catch { }
        }
        currentDiff = allDiffs
    }

    func push() async {
        isSyncing = true
        error = nil
        do {
            try await gitService.push(at: repository.path)
            await refreshRemoteStatus()
        } catch {
            self.error = error.localizedDescription
        }
        isSyncing = false
    }

    func pull() async {
        isSyncing = true
        error = nil
        do {
            try await gitService.pull(at: repository.path)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
        isSyncing = false
    }

    private func refreshRemoteStatus() async {
        hasRemote = await gitService.hasRemote(at: repository.path)
        if hasRemote {
            let counts = await gitService.aheadBehind(at: repository.path)
            commitsAhead = counts.ahead
            commitsBehind = counts.behind
        }
    }

    static let allChangesTag = "__all__"
    static let folderTagPrefix = "__folder__:"
    static let terminalTagPrefix = "__terminal__:"

    var panelTerminal: TerminalSession? {
        if let id = panelTerminalID {
            return terminalSessions.first { $0.id == id } ?? terminalSessions.first
        }
        return terminalSessions.first
    }

    var isTerminalSelected: Bool {
        guard let sel = selectedFilePath else { return false }
        return sel.hasPrefix(Self.terminalTagPrefix)
    }

    var selectedTerminal: TerminalSession? {
        guard let sel = selectedFilePath,
              sel.hasPrefix(Self.terminalTagPrefix) else { return nil }
        let idStr = String(sel.dropFirst(Self.terminalTagPrefix.count))
        guard let uuid = UUID(uuidString: idStr) else { return nil }
        return terminalSessions.first { $0.id == uuid }
    }

    func createTerminal() {
        terminalCounter += 1
        let session = TerminalSession(
            title: "Terminal \(terminalCounter)",
            workingDirectory: repository.path
        )
        session.startProcess()
        terminalSessions.append(session)
        selectedFilePath = Self.terminalTagPrefix + session.id.uuidString
    }

    func launchQuickItem(_ item: QuickLaunchItem) {
        terminalCounter += 1
        let session = TerminalSession(
            title: item.name,
            workingDirectory: repository.path
        )
        let fullCommand = item.arguments.isEmpty ? item.command : "\(item.command) \(item.arguments)"
        if item.isPlainTerminal {
            session.startProcess()
        } else {
            session.startProcess(initialCommand: fullCommand)
        }
        terminalSessions.append(session)
        panelTerminalID = session.id
        isTerminalPanelVisible = true
    }

    func createTerminalInPanel() {
        terminalCounter += 1
        let session = TerminalSession(
            title: "Terminal \(terminalCounter)",
            workingDirectory: repository.path
        )
        session.startProcess()
        terminalSessions.append(session)
        panelTerminalID = session.id
        isTerminalPanelVisible = true
    }

    func showInPanel(_ session: TerminalSession) {
        panelTerminalID = session.id
        isTerminalPanelVisible = true
    }

    func closeTerminal(_ session: TerminalSession) {
        session.terminate()
        let wasPanel = panelTerminalID == session.id
        terminalSessions.removeAll { $0.id == session.id }
        if selectedFilePath == Self.terminalTagPrefix + session.id.uuidString {
            selectedFilePath = nil
        }
        if wasPanel {
            panelTerminalID = terminalSessions.first?.id
            if terminalSessions.isEmpty {
                isTerminalPanelVisible = false
            }
        }
    }

    func toggleTerminalPanel() {
        isTerminalPanelVisible.toggle()
        if isTerminalPanelVisible && terminalSessions.isEmpty {
            createTerminalInPanel()
        }
    }

    func terminateAllTerminals() {
        for session in terminalSessions {
            session.terminate()
        }
        terminalSessions.removeAll()
        isTerminalPanelVisible = false
        panelTerminalID = nil
    }

    func selectFile(_ file: ChangedFile) async {
        selectedFilePath = file.path
        await loadDiff(for: file.path)
    }

    func selectFiles(_ files: [ChangedFile]) async {
        isLoading = true
        var allDiffs: [DiffResult] = []
        for file in files {
            do {
                let rawDiff: String
                if file.status == .untracked {
                    rawDiff = try await gitService.diffUntrackedFile(at: repository.path, file: file.path)
                } else {
                    rawDiff = try await gitService.diffForFile(at: repository.path, file: file.path, staged: file.isStaged)
                }
                allDiffs.append(contentsOf: DiffParser.parse(rawDiff))
            } catch {
                // Skip files that fail to diff
            }
        }
        currentDiff = allDiffs
        isLoading = false
    }

    func toggleStaging(for file: ChangedFile) {
        guard let index = changedFiles.firstIndex(where: { $0.id == file.id }) else { return }
        changedFiles[index].isStaged.toggle()
    }

    func toggleAllStaging() {
        let allStaged = changedFiles.allSatisfy(\.isStaged)
        for i in changedFiles.indices {
            changedFiles[i].isStaged = !allStaged
        }
    }

    func setStaging(_ staged: Bool, for files: [ChangedFile]) {
        for file in files {
            if let index = changedFiles.firstIndex(where: { $0.id == file.id }) {
                changedFiles[index].isStaged = staged
            }
        }
    }

    func commit() async {
        guard !commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              stagedCount > 0 else { return }

        isLoading = true
        error = nil
        do {
            // Stage the selected files
            let filesToStage = stagedFiles.map(\.path)
            try await gitService.stage(files: filesToStage, at: repository.path)

            // Commit
            try await gitService.commit(message: commitMessage, at: repository.path)
            commitMessage = ""

            // Refresh
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func loadDiff(for path: String) async {
        guard let file = changedFiles.first(where: { $0.path == path }) else { return }
        do {
            let rawDiff: String
            if file.status == .untracked {
                rawDiff = try await gitService.diffUntrackedFile(at: repository.path, file: path)
            } else {
                rawDiff = try await gitService.diffForFile(at: repository.path, file: path, staged: file.isStaged)
            }
            currentDiff = DiffParser.parse(rawDiff)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
