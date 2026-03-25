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
            } else {
                List(selection: Binding(
                    get: { appState.selectedViewModel?.selectedFilePath },
                    set: { newPath in
                        if let path = newPath,
                           let vm = appState.selectedViewModel,
                           let file = vm.changedFiles.first(where: { $0.path == path }) {
                            Task { await vm.selectFile(file) }
                        }
                    }
                )) {
                    ForEach(appState.repositories) { repo in
                        if let vm = appState.repositoryViewModels[repo.id] {
                            RepositorySection(repository: repo, viewModel: vm)
                        }
                    }
                }
                .listStyle(.sidebar)

                Divider()

                if let vm = appState.selectedViewModel {
                    CommitView(viewModel: vm)
                        .padding(12)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if appState.repositories.count > 1 {
                ProjectTabBar()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { appState.addRepository() }) {
                    Label("Add Repository", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                if let vm = appState.selectedViewModel {
                    Button(action: { Task { await vm.refresh() } }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .frame(minWidth: 260)
    }
}
