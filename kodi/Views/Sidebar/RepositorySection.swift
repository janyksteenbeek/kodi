import SwiftUI

struct RepositorySection: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        if viewModel.changedFiles.isEmpty {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ContentUnavailableView("No changes", systemImage: "checkmark.circle")
            }
        } else if appState.groupByFolder {
            let tree = FileTreeNode.buildTree(from: viewModel.changedFiles)
            ForEach(tree) { node in
                FileTreeNodeView(node: node, viewModel: viewModel)
            }
        } else {
            ForEach(viewModel.changedFiles) { file in
                ChangedFileRow(file: file, viewModel: viewModel)
                    .tag(file.path)
            }
        }
    }

    @Environment(AppState.self) private var appState
}
