import SwiftUI

struct FileTreeNodeView: View {
    let node: FileTreeNode
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        if node.isFolder {
            FolderNodeView(node: node, viewModel: viewModel)
        } else if let file = node.file {
            ChangedFileRow(file: file, viewModel: viewModel)
                .tag(file.path)
        }
    }
}

private struct FolderNodeView: View {
    let node: FileTreeNode
    @Bindable var viewModel: RepositoryViewModel
    @State private var isExpanded = true

    private var allFiles: [ChangedFile] { node.allFiles }
    private var allStaged: Bool { allFiles.allSatisfy(\.isStaged) }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(node.children) { child in
                FileTreeNodeView(node: child, viewModel: viewModel)
            }
        } label: {
            HStack(spacing: 6) {
                Toggle("", isOn: Binding(
                    get: { allStaged },
                    set: { newValue in viewModel.setStaging(newValue, for: allFiles) }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()

                Image(systemName: isExpanded ? "folder.fill" : "folder")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(node.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(node.name)

                Spacer()

                Text("\(node.fileCount)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
            .tag(RepositoryViewModel.folderTagPrefix + node.id)
        }
    }
}
