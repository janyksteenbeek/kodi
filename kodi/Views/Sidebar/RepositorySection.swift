import SwiftUI

struct RepositorySection: View {
    @Bindable var viewModel: RepositoryViewModel
    @AppStorage("groupByFolder") private var groupByFolder = true

    var body: some View {
        if viewModel.changedFiles.isEmpty {
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
}
