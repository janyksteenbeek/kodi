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

    private var isOpen: Bool {
        viewModel.editorSessions.contains { $0.relativePath == node.id }
    }

    private var changedStatus: ChangedFile.FileStatus? {
        viewModel.changedFiles.first { $0.path == node.id }?.status
    }

    private var fileRow: some View {
        HStack(spacing: 6) {
            FileIconView(fileName: node.name)
            Text(node.name)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            if isOpen {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .help("Open in editor")
            }
            if let status = changedStatus {
                Text(status.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(status.color)
                    .help(status.displayName)
            }
        }
        .contentShape(Rectangle())
        .tag(node.id)
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
