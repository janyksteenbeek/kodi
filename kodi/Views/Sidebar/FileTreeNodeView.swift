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
            Toggle(isOn: Binding(
                get: { allStaged },
                set: { newValue in viewModel.setStaging(newValue, for: allFiles) }
            )) {
                Label {
                    Text(node.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .help(node.name)
                } icon: {
                    Image(systemName: isExpanded ? "folder.fill" : "folder")
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.checkbox)
            .badge(node.fileCount)
            .tag(RepositoryViewModel.folderTagPrefix + node.id)
        }
    }
}
