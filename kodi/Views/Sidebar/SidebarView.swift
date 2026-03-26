import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: RepositoryViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        List(selection: Binding(
            get: { viewModel.selectedFilePath },
            set: { newValue in
                viewModel.selectedFilePath = newValue

                if let value = newValue {
                    if value.hasPrefix(RepositoryViewModel.terminalTagPrefix) {
                        // Terminal selected — no diff loading needed
                    } else if value.hasPrefix(RepositoryViewModel.folderTagPrefix) {
                        let folderId = String(value.dropFirst(RepositoryViewModel.folderTagPrefix.count))
                        let tree = FileTreeNode.buildTree(from: viewModel.changedFiles)
                        if let folderFiles = findFolderFiles(folderId, in: tree) {
                            Task { await viewModel.selectFiles(folderFiles) }
                        }
                    } else if let file = viewModel.changedFiles.first(where: { $0.path == value }) {
                        Task { await viewModel.selectFile(file) }
                    }
                } else {
                    Task { await viewModel.selectFiles(viewModel.changedFiles) }
                }
            }
        )) {
            TerminalSection(viewModel: viewModel)

            Section("Changes") {
                RepositorySection(viewModel: viewModel)
            }
        }
        .listStyle(.sidebar)
        .onKeyPress(.escape) {
            viewModel.selectedFilePath = nil
            Task { await viewModel.selectFiles(viewModel.changedFiles) }
            return .handled
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            QuickLaunchBar(viewModel: viewModel)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CommitView(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.addRepository() }) {
                    Label("Add Repository", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if !viewModel.changedFiles.isEmpty {
                    let allStaged = viewModel.changedFiles.allSatisfy(\.isStaged)
                    Button {
                        viewModel.setStaging(!allStaged, for: viewModel.changedFiles)
                    } label: {
                        Label(
                            allStaged ? "Unstage All" : "Stage All",
                            systemImage: allStaged ? "square" : "checkmark.square.fill"
                        )
                    }
                    .help(allStaged ? "Unstage all files" : "Stage all files")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        Task { await viewModel.refresh() }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.groupByFolder.toggle()
                        }
                    } label: {
                        Label(
                            appState.groupByFolder ? "Flat List" : "Group by Folder",
                            systemImage: appState.groupByFolder ? "list.bullet" : "folder"
                        )
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
            }
        }
        .frame(minWidth: 260)
    }

    private func findFolderFiles(_ folderId: String, in nodes: [FileTreeNode]) -> [ChangedFile]? {
        for node in nodes {
            if node.isFolder && node.id == folderId {
                return node.allFiles
            }
            if node.isFolder, let found = findFolderFiles(folderId, in: node.children) {
                return found
            }
        }
        return nil
    }
}
