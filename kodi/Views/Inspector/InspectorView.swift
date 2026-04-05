import SwiftUI

struct InspectorView: View {
    @Bindable var viewModel: RepositoryViewModel

    private var tree: [DirectoryTreeNode] {
        DirectoryTreeNode.buildTree(from: viewModel.directoryFiles)
    }

    var body: some View {
        List(selection: Binding(
            get: { viewModel.inspectorSelection },
            set: { newValue in
                let previous = viewModel.inspectorSelection
                viewModel.inspectorSelection = newValue
                handleSelectionChange(from: previous, to: newValue)
            }
        )) {
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
    }

    private func handleSelectionChange(from previous: Set<String>, to newValue: Set<String>) {
        // Single-click: replace editor with just that file.
        // Cmd/shift-click (building multi-selection): don't touch editor — user
        // confirms with Enter.
        guard newValue.count == 1, let path = newValue.first else { return }
        if previous == newValue { return }
        viewModel.closeAllEditors()
        viewModel.openFile(path)
    }

    private func openFiles(_ paths: [String]) {
        viewModel.closeAllEditors()
        for path in paths.sorted() {
            viewModel.openFile(path)
        }
    }
}
