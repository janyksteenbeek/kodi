import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: RepositoryViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        List(selection: Binding(
            get: { viewModel.selectedFilePaths },
            set: { newValue in
                viewModel.selectedFilePaths = newValue

                // Update legacy single selection for terminal/folder compat
                if newValue.count == 1, let single = newValue.first {
                    viewModel.selectedFilePath = single
                } else {
                    viewModel.selectedFilePath = nil
                }

                handleSelectionChange(newValue)
            }
        )) {
            TerminalSection(viewModel: viewModel)

            Section {
                RepositorySection(viewModel: viewModel)
            } header: {
                Button {
                    viewModel.selectedFilePaths = []
                    viewModel.selectedFilePath = nil
                    Task { await viewModel.selectFiles(viewModel.changedFiles) }
                } label: {
                    Text("Changes")
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .onKeyPress(.escape) {
            viewModel.selectedFilePaths = []
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

    private func handleSelectionChange(_ selection: Set<String>) {
        if selection.isEmpty {
            Task { await viewModel.selectFiles(viewModel.changedFiles) }
            return
        }

        // Single terminal selected
        if selection.count == 1, let single = selection.first,
           single.hasPrefix(RepositoryViewModel.terminalTagPrefix) {
            return
        }

        // Single folder selected
        if selection.count == 1, let single = selection.first,
           single.hasPrefix(RepositoryViewModel.folderTagPrefix) {
            let folderId = String(single.dropFirst(RepositoryViewModel.folderTagPrefix.count))
            let tree = FileTreeNode.buildTree(from: viewModel.changedFiles)
            if let folderFiles = findFolderFiles(folderId, in: tree) {
                Task { await viewModel.selectFiles(folderFiles) }
            }
            return
        }

        // One or more files selected
        let selectedFiles = viewModel.changedFiles.filter { selection.contains($0.path) }
        if !selectedFiles.isEmpty {
            Task { await viewModel.selectFiles(selectedFiles) }
        }
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
