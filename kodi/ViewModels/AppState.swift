import SwiftUI

@Observable
final class AppState {
    var repositories: [GitRepository] = []
    var repositoryViewModels: [UUID: RepositoryViewModel] = [:]
    var isTerminating = false

    private let fileWatcher = FileWatcherService()
    private let gitService = GitService()

    var openRepositoryTab: ((UUID) -> Void)?

    init() {
        fileWatcher.onChange = { [weak self] url in
            guard let self else { return }
            let autoRefresh = UserDefaults.standard.object(forKey: "autoRefresh") as? Bool ?? true
            guard autoRefresh else { return }
            if let repo = repositories.first(where: { $0.path == url }),
               let vm = repositoryViewModels[repo.id] {
                Task { await vm.refresh() }
            }
        }
    }

    func loadSavedRepositories() -> [UUID] {
        var ids: [UUID] = []
        let saved = BookmarkManager.loadRepositories()
        for repo in saved {
            if let bookmarkData = repo.bookmarkData,
               let url = try? BookmarkManager.resolveBookmark(bookmarkData) {
                _ = url.startAccessingSecurityScopedResource()
                var resolved = repo
                resolved.path = url
                if addRepositoryDirectly(resolved) {
                    ids.append(resolved.id)
                }
            }
        }
        return ids
    }

    func addRepository() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a git repository folder"
        panel.prompt = "Add Repository"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // If this repository is already open, switch to its existing tab
        if let existing = repositories.first(where: { $0.path == url }) {
            openRepositoryTab?(existing.id)
            return
        }

        Task {
            guard await gitService.isGitRepository(at: url) else { return }

            await MainActor.run {
                let bookmarkData = try? BookmarkManager.saveBookmark(for: url)
                let repo = GitRepository(path: url, bookmarkData: bookmarkData)
                _ = addRepositoryDirectly(repo)
                saveRepositories()
                openRepositoryTab?(repo.id)
            }
        }
    }

    func removeRepository(id: UUID) {
        if let repo = repositories.first(where: { $0.id == id }) {
            fileWatcher.unwatch(directory: repo.path)
            repo.path.stopAccessingSecurityScopedResource()
        }
        repositoryViewModels[id]?.terminateAllTerminals()
        repositories.removeAll { $0.id == id }
        repositoryViewModels.removeValue(forKey: id)
        saveRepositories()
    }

    func viewModel(for id: UUID) -> RepositoryViewModel? {
        repositoryViewModels[id]
    }

    @discardableResult
    private func addRepositoryDirectly(_ repo: GitRepository) -> Bool {
        guard !repositories.contains(where: { $0.path == repo.path }) else { return false }
        repositories.append(repo)
        let vm = RepositoryViewModel(repository: repo, gitService: gitService)
        repositoryViewModels[repo.id] = vm
        fileWatcher.watch(directory: repo.path)
        Task { await vm.refresh() }
        return true
    }

    private func saveRepositories() {
        BookmarkManager.saveRepositories(repositories)
    }
}
