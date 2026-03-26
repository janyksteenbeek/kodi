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
    var diffMode: DiffMode = .unified
    var hasRemote: Bool = false
    var commitsAhead: Int = 0
    var commitsBehind: Int = 0

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

    init(repository: GitRepository, gitService: GitService) {
        self.id = repository.id
        self.repository = repository
        self.gitService = gitService
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
            // Reload diff for selected file if still present
            if let path = selectedFilePath {
                if changedFiles.contains(where: { $0.path == path }) {
                    await loadDiff(for: path)
                } else {
                    selectedFilePath = nil
                    currentDiff = []
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
        await refreshRemoteStatus()
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
