import Foundation

@MainActor
@Observable
final class HistoryViewModel {
    let repository: GitRepository

    private(set) var commits: [Commit] = []
    private(set) var isLoading: Bool = false
    private(set) var canLoadMore: Bool = true
    private(set) var branchName: String?
    var errorMessage: String?

    private let gitService: GitService
    private let pageSize = 100

    init(repository: GitRepository, gitService: GitService = GitService()) {
        self.repository = repository
        self.gitService = gitService
    }

    func loadInitial() async {
        commits = []
        canLoadMore = true
        await reloadBranch()
        await fetchPage(skip: 0, replace: true)
    }

    func loadMore() async {
        guard !isLoading, canLoadMore else { return }
        await fetchPage(skip: commits.count, replace: false)
    }

    func loadDiff(for sha: String) async throws -> [DiffResult] {
        let raw = try await gitService.show(commit: sha, at: repository.path)
        return DiffParser.parse(raw)
    }

    private func reloadBranch() async {
        do {
            branchName = try await gitService.currentBranch(at: repository.path)
        } catch {
            branchName = nil
        }
    }

    private func fetchPage(skip: Int, replace: Bool) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let raw = try await gitService.log(
                branch: branchName,
                skip: skip,
                limit: pageSize,
                at: repository.path
            )
            let page = CommitLogParser.parse(raw)
            if replace {
                commits = page
            } else {
                commits.append(contentsOf: page)
            }
            canLoadMore = page.count == pageSize
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            canLoadMore = false
        }
    }
}
