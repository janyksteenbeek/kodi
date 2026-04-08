import SwiftUI
@Observable
final class RepositoryViewModel: Identifiable {
    let id: UUID
    let repository: GitRepository

    var changedFiles: [ChangedFile] = []
    var selectedFilePath: String?
    var selectedFilePaths: Set<String> = []
    var currentDiff: [DiffResult] = []
    var commitMessage: String = ""
    var isLoading: Bool = false
    var isSyncing: Bool = false
    var isGeneratingMessage: Bool = false
    var error: String?
    var diffMode: DiffMode
    var hasRemote: Bool = false
    var commitsAhead: Int = 0
    var commitsBehind: Int = 0

    // Branch state
    var currentBranch: String = ""
    var localBranches: [String] = []
    var remoteBranches: [String] = []
    var isFetching: Bool = false
    var isSwitchingBranch: Bool = false

    var terminalSessions: [TerminalSession] = []
    private var terminalCounter: Int = 0
    var isTerminalPanelVisible: Bool = false
    var terminalPanelMode: TerminalPanelMode
    var panelTerminalIDs: [UUID] = []
    var terminalPaneLayout: PaneLayout
    var editorPaneLayout: PaneLayout

    // Directory tree & editor
    var directoryFiles: [String] = []
    var isInspectorVisible: Bool = false
    var editorSessions: [EditorSession] = []
    var pendingCloseSession: EditorSession?
    var showUnsavedAlert: Bool = false
    var inspectorSelection: Set<String> = []
    var isGlobalSearchVisible: Bool = false

    var isEditorVisible: Bool { !editorSessions.isEmpty }

    var hasAnyUnsavedChanges: Bool {
        editorSessions.contains { $0.hasUnsavedChanges }
    }

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

    typealias TerminalPaneLayout = PaneLayout

    init(repository: GitRepository, gitService: GitService) {
        self.id = repository.id
        self.repository = repository
        self.gitService = gitService

        let savedDiffMode = UserDefaults.standard.string(forKey: "defaultDiffMode") ?? "unified"
        self.diffMode = DiffMode(rawValue: savedDiffMode == "sideBySide" ? "Side by Side" : "Unified") ?? .unified

        let savedPanelMode = UserDefaults.standard.string(forKey: "defaultTerminalPanelMode") ?? "right"
        self.terminalPanelMode = TerminalPanelMode(rawValue: savedPanelMode == "right" ? "Right" : "Bottom") ?? .right

        let savedPaneLayout = UserDefaults.standard.string(forKey: "defaultTerminalPaneLayout") ?? "Side by Side"
        self.terminalPaneLayout = PaneLayout(rawValue: savedPaneLayout) ?? .horizontal
        self.editorPaneLayout = .horizontal
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
        await refreshBranches()
        await refreshRemoteStatus()
        await loadDirectoryTree()
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

    var panelTerminalID: UUID? {
        get { panelTerminalIDs.first }
        set {
            if let id = newValue {
                panelTerminalIDs = [id]
            } else {
                panelTerminalIDs = []
            }
        }
    }

    var panelTerminal: TerminalSession? {
        panelTerminals.first ?? terminalSessions.first
    }

    var panelTerminals: [TerminalSession] {
        let resolved = panelTerminalIDs.compactMap { id in
            terminalSessions.first { $0.id == id }
        }
        return resolved.isEmpty ? [] : resolved
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

    var selectedTerminals: [TerminalSession] {
        let tags = selectedFilePaths.filter { $0.hasPrefix(Self.terminalTagPrefix) }
        return terminalSessions.filter { session in
            tags.contains(Self.terminalTagPrefix + session.id.uuidString)
        }
    }

    func isTerminalInPanel(_ session: TerminalSession) -> Bool {
        panelTerminalIDs.contains(session.id)
    }

    func pinTerminalsToPanel(_ sessions: [TerminalSession]) {
        panelTerminalIDs = sessions.map(\.id)
        isTerminalPanelVisible = true
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
        var args = item.arguments
        // Append default AI args if the item has no custom args
        if args.isEmpty {
            let program = TerminalProgram.detect(from: item.command)
            switch program {
            case .claude: args = UserDefaults.standard.string(forKey: "claudeArgs") ?? ""
            case .codex: args = UserDefaults.standard.string(forKey: "codexArgs") ?? ""
            case .opencode: args = UserDefaults.standard.string(forKey: "opencodeArgs") ?? ""
            case .shell: break
            }
        }
        let fullCommand = args.isEmpty ? item.command : "\(item.command) \(args)"
        let program = TerminalProgram.detect(from: item.command)
        if item.isPlainTerminal {
            session.program = .shell
            session.startProcess()
        } else {
            session.startProcess(initialCommand: fullCommand, program: program)
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
        let wasInPanel = panelTerminalIDs.contains(session.id)
        terminalSessions.removeAll { $0.id == session.id }
        panelTerminalIDs.removeAll { $0 == session.id }
        selectedFilePaths.remove(Self.terminalTagPrefix + session.id.uuidString)
        if selectedFilePath == Self.terminalTagPrefix + session.id.uuidString {
            selectedFilePath = nil
        }
        if wasInPanel && panelTerminalIDs.isEmpty {
            if let first = terminalSessions.first {
                panelTerminalIDs = [first.id]
            } else {
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
        panelTerminalIDs = []
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

    @available(macOS 26.0, *)
    func generateCommitMessage() async {
        guard stagedCount > 0 else { return }

        isGeneratingMessage = true
        error = nil
        do {
            // Collect diffs for all files the user has staged in the UI
            var diff = ""
            for file in stagedFiles {
                let fileDiff: String
                if file.status == .untracked {
                    fileDiff = try await gitService.diffUntrackedFile(at: repository.path, file: file.path)
                } else {
                    fileDiff = try await gitService.diffForFile(at: repository.path, file: file.path, staged: file.isStaged)
                }
                if !fileDiff.isEmpty {
                    diff += fileDiff + "\n"
                }
            }
            let message = try await CommitMessageGenerator().generate(diff: diff, stagedFiles: stagedFiles)
            commitMessage = message
        } catch {
            self.error = error.localizedDescription
        }
        isGeneratingMessage = false
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

    // MARK: - Branches

    func refreshBranches() async {
        do {
            currentBranch = try await gitService.currentBranch(at: repository.path)
            localBranches = try await gitService.localBranches(at: repository.path)
            remoteBranches = try await gitService.remoteBranches(at: repository.path)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func checkoutBranch(_ branch: String) async {
        isSwitchingBranch = true
        error = nil
        do {
            try await gitService.checkout(branch: branch, at: repository.path)
            await refreshBranches()
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
        isSwitchingBranch = false
    }

    func createAndCheckoutBranch(_ name: String) async {
        isSwitchingBranch = true
        error = nil
        do {
            try await gitService.createBranch(name: name, at: repository.path)
            await refreshBranches()
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
        isSwitchingBranch = false
    }

    func fetchRemote() async {
        isFetching = true
        error = nil
        do {
            try await gitService.fetch(at: repository.path)
            await refreshBranches()
            await refreshRemoteStatus()
        } catch {
            self.error = error.localizedDescription
        }
        isFetching = false
    }

    // MARK: - Directory Tree & Editor

    func loadDirectoryTree() async {
        do {
            directoryFiles = try await gitService.listAllFiles(at: repository.path)
        } catch {
            // Silently fail — directory tree is non-critical
        }
    }

    func openFile(_ relativePath: String) {
        // If already open, bring to front
        if let index = editorSessions.firstIndex(where: { $0.relativePath == relativePath }) {
            let session = editorSessions.remove(at: index)
            editorSessions.append(session)
            return
        }

        // Append a placeholder session immediately so the UI can render a
        // loading state on the same frame the user clicked. Disk I/O happens
        // off the main thread; NSView setup runs on MainActor once the read
        // completes.
        let session = EditorSession(
            relativePath: relativePath,
            content: "",
            repositoryPath: repository.path
        )
        editorSessions.append(session)

        let fullPath = repository.path.appendingPathComponent(relativePath).path
        Task.detached {
            let data = FileManager.default.contents(atPath: fullPath)
            let content = data.flatMap { String(data: $0, encoding: .utf8) }
            await MainActor.run {
                // Session may have been closed while reading.
                guard self.editorSessions.contains(where: { $0.id == session.id }) else { return }
                guard let content else {
                    self.error = "Cannot read file"
                    self.editorSessions.removeAll { $0.id == session.id }
                    return
                }
                session.content = content
                session.isLoading = false
            }
        }
    }

    func closeEditor(_ session: EditorSession) {
        editorSessions.removeAll { $0.id == session.id }
    }

    func closeAllEditors() {
        editorSessions.removeAll()
    }

    func saveEditor(_ session: EditorSession) {
        session.save()
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
