import SwiftUI

@Observable
final class AppState {
    var repositories: [GitRepository] = []
    var selectedRepositoryID: UUID?
    var repositoryViewModels: [UUID: RepositoryViewModel] = [:]

    private let fileWatcher = FileWatcherService()
    private let gitService = GitService()

    var selectedRepository: GitRepository? {
        repositories.first { $0.id == selectedRepositoryID }
    }

    var selectedViewModel: RepositoryViewModel? {
        guard let id = selectedRepositoryID else { return nil }
        return repositoryViewModels[id]
    }

    init() {
        fileWatcher.onChange = { [weak self] url in
            guard let self else { return }
            // Find the repository for this URL and refresh it
            if let repo = repositories.first(where: { $0.path == url }),
               let vm = repositoryViewModels[repo.id] {
                Task { await vm.refresh() }
            }
        }
    }

    func loadSavedRepositories() {
        let saved = BookmarkManager.loadRepositories()
        for repo in saved {
            if let bookmarkData = repo.bookmarkData,
               let url = try? BookmarkManager.resolveBookmark(bookmarkData) {
                _ = url.startAccessingSecurityScopedResource()
                var resolved = repo
                resolved.path = url
                addRepositoryDirectly(resolved)
            }
        }
        // Select first if nothing selected
        if selectedRepositoryID == nil {
            selectedRepositoryID = repositories.first?.id
        }
    }

    func addRepository() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a git repository folder"
        panel.prompt = "Add Repository"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            guard await gitService.isGitRepository(at: url) else {
                // Not a git repo — could show an alert
                return
            }

            let bookmarkData = try? BookmarkManager.saveBookmark(for: url)
            let repo = GitRepository(path: url, bookmarkData: bookmarkData)
            addRepositoryDirectly(repo)
            selectedRepositoryID = repo.id
            saveRepositories()
        }
    }

    func removeRepository(id: UUID) {
        if let repo = repositories.first(where: { $0.id == id }) {
            fileWatcher.unwatch(directory: repo.path)
            repo.path.stopAccessingSecurityScopedResource()
        }
        repositories.removeAll { $0.id == id }
        repositoryViewModels.removeValue(forKey: id)
        if selectedRepositoryID == id {
            selectedRepositoryID = repositories.first?.id
        }
        saveRepositories()
    }

    private func addRepositoryDirectly(_ repo: GitRepository) {
        guard !repositories.contains(where: { $0.path == repo.path }) else { return }
        repositories.append(repo)
        let vm = RepositoryViewModel(repository: repo, gitService: gitService)
        repositoryViewModels[repo.id] = vm
        fileWatcher.watch(directory: repo.path)
        Task { await vm.refresh() }
    }

    private func saveRepositories() {
        BookmarkManager.saveRepositories(repositories)
    }
}
