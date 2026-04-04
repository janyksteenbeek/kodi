import SwiftUI

struct DirectoryTreeNodeView: View {
    let node: DirectoryTreeNode
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        if node.isFolder {
            FolderNodeView(node: node, viewModel: viewModel)
        } else {
            fileRow
        }
    }

    private var fileRow: some View {
        Button {
            viewModel.openFile(node.id)
        } label: {
            HStack(spacing: 6) {
                FileIconView(fileName: node.name)
                Text(node.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 1)
        .background(
            viewModel.editingFilePath == node.id
                ? Color.accentColor.opacity(0.15)
                : Color.clear
        )
        .clipShape(.rect(cornerRadius: 4))
    }
}

private struct FolderNodeView: View {
    let node: DirectoryTreeNode
    @Bindable var viewModel: RepositoryViewModel
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(node.children) { child in
                DirectoryTreeNodeView(node: child, viewModel: viewModel)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "folder.fill" : "folder")
                    .foregroundStyle(.secondary)
                    .imageScale(.medium)
                    .frame(width: 16)
                Text(node.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text("\(node.fileCount)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
