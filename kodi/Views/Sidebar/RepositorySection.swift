import SwiftUI

struct RepositorySection: View {
    @Bindable var viewModel: RepositoryViewModel
    @AppStorage("groupByFolder") private var groupByFolder = true
    @AppStorage("showUntrackedFiles") private var showUntrackedFiles = true

    @State private var cachedTree: [FileTreeNode] = []
    @State private var treeTask: Task<Void, Never>?

    private var visibleFiles: [ChangedFile] {
        if showUntrackedFiles {
            return viewModel.changedFiles
        }
        return viewModel.changedFiles.filter { $0.status != .untracked }
    }

    var body: some View {
        content
            .onAppear { rebuildTreeIfNeeded() }
            .onChange(of: viewModel.changedFiles) { rebuildTreeIfNeeded() }
            .onChange(of: showUntrackedFiles) { rebuildTreeIfNeeded() }
            .onChange(of: groupByFolder) { rebuildTreeIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        let files = visibleFiles
        if files.isEmpty {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("No changes")
                            .font(.callout.weight(.medium))
                        Text("Working tree is clean")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }
        } else if groupByFolder {
            ForEach(cachedTree) { node in
                FileTreeNodeView(node: node, viewModel: viewModel)
            }
        } else {
            ForEach(files) { file in
                ChangedFileRow(file: file, viewModel: viewModel)
                    .tag(file.path)
            }
        }
    }

    private func rebuildTreeIfNeeded() {
        guard groupByFolder else { return }
        let files = visibleFiles
        treeTask?.cancel()
        treeTask = Task {
            let newTree = await Task.detached(priority: .userInitiated) {
                FileTreeNode.buildTree(from: files)
            }.value
            if Task.isCancelled { return }
            await MainActor.run {
                self.cachedTree = newTree
            }
        }
    }
}
