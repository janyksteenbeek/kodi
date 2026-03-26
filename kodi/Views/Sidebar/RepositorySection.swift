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
                Text("No changes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "tray.full")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text("All Changes")

                Spacer()

                Text("\(viewModel.changedFiles.count)")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.fill.tertiary, in: .capsule)
            }
            .tag(RepositoryViewModel.allChangesTag)

            if appState.groupByFolder {
                let tree = FileTreeNode.buildTree(from: viewModel.changedFiles)
                ForEach(tree) { node in
                    FileTreeNodeView(node: node, viewModel: viewModel)
                }
            } else {
                ForEach(viewModel.changedFiles) { file in
                    ChangedFileRow(file: file, viewModel: viewModel, showDirectory: true)
                        .tag(file.path)
                }
            }
        }
    }

    @Environment(AppState.self) private var appState
}
