import SwiftUI

struct HistoryWindowView: View {
    let repository: GitRepository

    @State private var viewModel: HistoryViewModel
    @State private var selectedSHA: String?
    @State private var presentedCommit: Commit?

    init(repository: GitRepository) {
        self.repository = repository
        _viewModel = State(initialValue: HistoryViewModel(repository: repository))
    }

    var body: some View {
        Group {
            if let message = viewModel.errorMessage, viewModel.commits.isEmpty {
                ContentUnavailableView(
                    "Couldn't load history",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            } else if viewModel.commits.isEmpty && viewModel.isLoading {
                ProgressView("Loading history…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.commits.isEmpty {
                ContentUnavailableView(
                    "No commits",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("This branch has no commits yet.")
                )
            } else {
                commitList
            }
        }
        .navigationTitle("History — \(repository.displayName)")
        .navigationSubtitle(subtitle)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if let branch = viewModel.branchName {
                    Label(branch, systemImage: "arrow.triangle.branch")
                        .font(.callout)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.loadInitial() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh history")
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            if viewModel.commits.isEmpty {
                await viewModel.loadInitial()
            }
        }
        .sheet(item: $presentedCommit) { commit in
            CommitDetailSheet(commit: commit, viewModel: viewModel)
        }
        .frame(minWidth: 560, minHeight: 480)
    }

    private var subtitle: String {
        let count = viewModel.commits.count
        let suffix = viewModel.canLoadMore ? "+" : ""
        return "\(count)\(suffix) commit\(count == 1 ? "" : "s")"
    }

    private var commitList: some View {
        List(selection: $selectedSHA) {
            if let message = viewModel.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .listRowSeparator(.hidden)
            }

            ForEach(viewModel.commits) { commit in
                CommitRow(commit: commit, isSelected: selectedSHA == commit.sha)
                    .tag(commit.sha)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
            }

            if viewModel.canLoadMore {
                Button {
                    Task { await viewModel.loadMore() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Label("Load more commits", systemImage: "arrow.down.circle")
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(viewModel.isLoading)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 1)
        .contextMenu(forSelectionType: String.self) { shas in
            if let sha = shas.first, let commit = viewModel.commits.first(where: { $0.sha == sha }) {
                Button("View Diff") { presentedCommit = commit }
                Button("Copy SHA") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(commit.sha, forType: .string)
                }
            }
        } primaryAction: { shas in
            if let sha = shas.first, let commit = viewModel.commits.first(where: { $0.sha == sha }) {
                presentedCommit = commit
            }
        }
    }
}
