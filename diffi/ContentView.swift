import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            if let vm = appState.selectedViewModel {
                DiffContentView(viewModel: vm)
            } else {
                ContentUnavailableView(
                    "Welcome to diffi",
                    systemImage: "arrow.triangle.branch",
                    description: Text("Add a git repository to start viewing diffs")
                )
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .task {
            appState.loadSavedRepositories()
        }
    }
}
