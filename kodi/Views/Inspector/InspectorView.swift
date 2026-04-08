import SwiftUI

struct InspectorView: View {
    @Bindable var viewModel: RepositoryViewModel
    @State private var isCreatingFile = false
    @State private var isCreatingFolder = false
    @State private var newItemName = ""

    private var tree: [DirectoryTreeNode] {
        DirectoryTreeNode.buildTree(from: viewModel.directoryFiles)
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: Binding(
                get: { viewModel.inspectorSelection },
                set: { newValue in
                    let previous = viewModel.inspectorSelection
                    viewModel.inspectorSelection = newValue
                    handleSelectionChange(from: previous, to: newValue)
                }
            )) {
                if isCreatingFile || isCreatingFolder {
                    newItemRow
                }
                ForEach(tree) { node in
                    DirectoryTreeNodeView(node: node, viewModel: viewModel)
                }
            }
            .listStyle(.sidebar)
            .onKeyPress(.return) {
                let files = Array(viewModel.inspectorSelection)
                if files.count > 1 {
                    openFiles(files)
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.escape) {
                if isCreatingFile || isCreatingFolder {
                    isCreatingFile = false
                    isCreatingFolder = false
                    newItemName = ""
                    return .handled
                }
                viewModel.inspectorSelection = []
                return .handled
            }
            .overlay {
                if viewModel.directoryFiles.isEmpty {
                    ContentUnavailableView(
                        "No Files",
                        systemImage: "folder",
                        description: Text("Repository has no files")
                    )
                }
            }

            Divider()

            bottomBar
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Menu {
                Button {
                    newItemName = ""
                    isCreatingFile = true
                    isCreatingFolder = false
                } label: {
                    Label("New File", systemImage: "doc.badge.plus")
                }

                Button {
                    newItemName = ""
                    isCreatingFolder = true
                    isCreatingFile = false
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            } label: {
                Image(systemName: "plus")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()

            Spacer()

            Text("\(viewModel.directoryFiles.count) files")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
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
    }

    private func commitNewItem() {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            isCreatingFile = false
            isCreatingFolder = false
            return
        }

        if isCreatingFolder {
            viewModel.createDirectory(named: name, inDirectory: nil)
        } else {
            viewModel.createFile(named: name, inDirectory: nil)
        }
        isCreatingFile = false
        isCreatingFolder = false
        newItemName = ""
    }

    private func handleSelectionChange(from previous: Set<String>, to newValue: Set<String>) {
        guard newValue.count == 1, let path = newValue.first else { return }
        if previous == newValue { return }

        if isFolder(path, in: tree) {
            viewModel.inspectorSelection = previous
            return
        }

        viewModel.closeAllEditors()
        viewModel.openFile(path)
    }

    private func isFolder(_ path: String, in nodes: [DirectoryTreeNode]) -> Bool {
        for node in nodes {
            if node.id == path { return node.isFolder }
            if node.isFolder, isFolder(path, in: node.children) { return true }
        }
        return false
    }

    private func openFiles(_ paths: [String]) {
        viewModel.closeAllEditors()
        for path in paths.sorted() {
            viewModel.openFile(path)
        }
    }
}
