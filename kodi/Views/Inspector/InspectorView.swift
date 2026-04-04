import SwiftUI

struct InspectorView: View {
    @Bindable var viewModel: RepositoryViewModel

    private var tree: [DirectoryTreeNode] {
        DirectoryTreeNode.buildTree(from: viewModel.directoryFiles)
    }

    var body: some View {
        List {
            ForEach(tree) { node in
                DirectoryTreeNodeView(node: node, viewModel: viewModel)
            }
        }
        .listStyle(.sidebar)
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
}
