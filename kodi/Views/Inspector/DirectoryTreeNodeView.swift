import SwiftUI
import AppKit

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
        .contextMenu { fileContextMenu }
    }

    @ViewBuilder
    private var fileContextMenu: some View {
        Button("Open in Editor") {
            viewModel.openFile(node.id)
        }

        Divider()

        Button("Reveal in Finder") {
            viewModel.revealInFinder(node.id)
        }

        Button("Open with Default App") {
            let url = viewModel.repository.path.appendingPathComponent(node.id)
            NSWorkspace.shared.open(url)
        }

        Divider()

        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(node.id, forType: .string)
        }

        Button("Copy Full Path") {
            let full = viewModel.repository.path.appendingPathComponent(node.id).path
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(full, forType: .string)
        }

        Button("Copy Name") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(node.name, forType: .string)
        }

        Divider()

        Button("Duplicate") {
            viewModel.duplicateFile(at: node.id)
        }

        Button("Delete", role: .destructive) {
            viewModel.deleteFileOrFolder(at: node.id)
        }
    }
}

private struct FolderNodeView: View {
    let node: DirectoryTreeNode
    @Bindable var viewModel: RepositoryViewModel
    @State private var isExpanded = false
    @State private var isCreatingFile = false
    @State private var isCreatingFolder = false
    @State private var newItemName = ""

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if isCreatingFile || isCreatingFolder {
                newItemRow
            }
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
        .contextMenu { folderContextMenu }
    }

    @ViewBuilder
    private var folderContextMenu: some View {
        Button("New File…") {
            newItemName = ""
            isCreatingFile = true
            isCreatingFolder = false
            isExpanded = true
        }

        Button("New Folder…") {
            newItemName = ""
            isCreatingFolder = true
            isCreatingFile = false
            isExpanded = true
        }

        Divider()

        Button("Reveal in Finder") {
            viewModel.revealInFinder(node.id)
        }

        Button("Open in Terminal") {
            let full = viewModel.repository.path.appendingPathComponent(node.id).path
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"), configuration: .init(), completionHandler: nil)
        }

        Divider()

        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(node.id, forType: .string)
        }

        Button("Copy Full Path") {
            let full = viewModel.repository.path.appendingPathComponent(node.id).path
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(full, forType: .string)
        }

        Divider()

        Button("Delete", role: .destructive) {
            viewModel.deleteFileOrFolder(at: node.id)
        }
    }

    private var newItemRow: some View {
        HStack(spacing: 6) {
            Image(systemName: isCreatingFolder ? "folder.badge.plus" : "doc.badge.plus")
                .foregroundStyle(.secondary)
                .frame(width: 16)
            TextField(isCreatingFolder ? "Folder name" : "File name", text: $newItemName)
                .textFieldStyle(.plain)
                .onSubmit {
                    commitNewItem()
                }
                .onExitCommand {
                    isCreatingFile = false
                    isCreatingFolder = false
                    newItemName = ""
                }
        }
        .padding(.vertical, 2)
    }

    private func commitNewItem() {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            isCreatingFile = false
            isCreatingFolder = false
            return
        }

        if isCreatingFolder {
            viewModel.createDirectory(named: name, inDirectory: node.id)
        } else {
            viewModel.createFile(named: name, inDirectory: node.id)
        }
        isCreatingFile = false
        isCreatingFolder = false
        newItemName = ""
    }
}
