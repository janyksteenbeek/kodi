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
                    set: { newPath in
                        if let path = newPath,
                           let file = vm.changedFiles.first(where: { $0.path == path }) {
                            Task { await vm.selectFile(file) }
                        }
                    }
                )) {
                    RepositorySection(repository: repo, viewModel: vm)
                }
                .listStyle(.sidebar)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !vm.changedFiles.isEmpty {
                        CommitView(viewModel: vm)
                    }
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
            ToolbarItem(placement: .automatic) {
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
                .help(appState.groupByFolder ? "Show as flat list" : "Group by folder")
            }
        }
        .frame(minWidth: 260)
    }
}
