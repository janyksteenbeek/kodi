import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: RepositoryViewModel
    @Environment(AppState.self) private var appState
    @AppStorage("groupByFolder") private var groupByFolder = true
    @AppStorage("sidebarWidth") private var sidebarWidth = 260.0

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
            QuickLaunchBar(viewModel: viewModel)
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

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
        .onKeyPress(.return) {
            let terminals = viewModel.selectedTerminals
            if terminals.count > 1 {
                viewModel.pinTerminalsToPanel(terminals)
                // Clear selection so user can navigate away while panes stay
                viewModel.selectedFilePaths = []
                viewModel.selectedFilePath = nil
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.escape) {
            viewModel.selectedFilePaths = []
            viewModel.selectedFilePath = nil
            Task { await viewModel.selectFiles(viewModel.changedFiles) }
            return .handled
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
                Menu {
                    Button(action: {
                        Task { await viewModel.refresh() }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            groupByFolder.toggle()
                        }
                    } label: {
                        Label(
                            groupByFolder ? "Flat List" : "Group by Folder",
                            systemImage: groupByFolder ? "list.bullet" : "folder"
                        )
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
            }
        }
        .frame(minWidth: sidebarWidth)
    }

    private func handleSelectionChange(_ selection: Set<String>) {
        // Close editors when selecting from sidebar
        viewModel.closeAllEditors()

        if selection.isEmpty {
            Task { await viewModel.selectFiles(viewModel.changedFiles) }
            return
        }

        // Multiple terminals selected — show multi-pane preview
        let terminalTags = selection.filter { $0.hasPrefix(RepositoryViewModel.terminalTagPrefix) }
        if terminalTags.count > 1 {
            let sessions = viewModel.selectedTerminals
            if sessions.count > 1 {
                viewModel.panelTerminalIDs = sessions.map(\.id)
                viewModel.isTerminalPanelVisible = true
            }
            return
        }

        // Single terminal selected — respect click action setting
        if selection.count == 1, let single = selection.first,
           single.hasPrefix(RepositoryViewModel.terminalTagPrefix) {
            let clickAction = UserDefaults.standard.string(forKey: "terminalClickAction") ?? "panel"
            if clickAction == "panel" {
                let idStr = String(single.dropFirst(RepositoryViewModel.terminalTagPrefix.count))
                if let uuid = UUID(uuidString: idStr),
                   let session = viewModel.terminalSessions.first(where: { $0.id == uuid }) {
                    viewModel.showInPanel(session)
                }
            }
            // "fullscreen" uses the default List selection behavior
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
