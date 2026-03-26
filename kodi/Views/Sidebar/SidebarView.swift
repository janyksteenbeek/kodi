import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            if appState.repositories.isEmpty {
                ContentUnavailableView {
                    Label("No Repositories", systemImage: "folder.badge.plus")
                } description: {
                    Text("Add a git repository to get started")
                } actions: {
                    Button("Add Repository") {
                        appState.addRepository()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else if let repo = appState.selectedRepository,
                      let vm = appState.selectedViewModel {
                List(selection: Binding(
                    get: { vm.selectedFilePath },
                    set: { newValue in
                        vm.selectedFilePath = newValue

                        if let value = newValue {
                            if value.hasPrefix(RepositoryViewModel.terminalTagPrefix) {
                                // Terminal selected — no diff loading needed
                            } else if value.hasPrefix(RepositoryViewModel.folderTagPrefix) {
                                let folderId = String(value.dropFirst(RepositoryViewModel.folderTagPrefix.count))
                                let tree = FileTreeNode.buildTree(from: vm.changedFiles)
                                if let folderFiles = findFolderFiles(folderId, in: tree) {
                                    Task { await vm.selectFiles(folderFiles) }
                                }
                            } else if let file = vm.changedFiles.first(where: { $0.path == value }) {
                                Task { await vm.selectFile(file) }
                            }
                        } else {
                            Task { await vm.selectFiles(vm.changedFiles) }
                        }
                    }
                )) {
                    TerminalSection(viewModel: vm)

                    Section("Changes") {
                        RepositorySection(viewModel: vm)
                    }
                }
                .listStyle(.sidebar)
                .safeAreaInset(edge: .top, spacing: 0) {
                    QuickLaunchBar(viewModel: vm)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    CommitView(viewModel: vm)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if appState.repositories.count > 1 {
                ProjectTabBar()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.addRepository() }) {
                    Label("Add Repository", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if let vm = appState.selectedViewModel, !vm.changedFiles.isEmpty {
                    let allStaged = vm.changedFiles.allSatisfy(\.isStaged)
                    Button {
                        vm.setStaging(!allStaged, for: vm.changedFiles)
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
                if appState.selectedViewModel != nil {
                    Menu {
                        Button(action: {
                            Task { await appState.selectedViewModel?.refresh() }
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
                        if appState.repositories.count > 1 {
                            Divider()
                            Button(role: .destructive, action: {
                                if let repo = appState.selectedRepository {
                                    withAnimation { appState.removeRepository(id: repo.id) }
                                }
                            }) {
                                Label("Remove Repository", systemImage: "trash")
                            }
                        }
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                    }
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
