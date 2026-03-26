import SwiftUI

@main
struct kodiApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 700)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("Open Repository…") {
                    appState.addRepository()
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Close Repository") {
                    if let repo = appState.selectedRepository {
                        appState.removeRepository(id: repo.id)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(appState.selectedRepository == nil)
            }

            // View menu
            CommandGroup(after: .toolbar) {
                if let vm = appState.selectedViewModel {
                    Button("Refresh") {
                        Task { await vm.refresh() }
                    }
                    .keyboardShortcut("r", modifiers: .command)

                    Divider()

                    let allStaged = vm.changedFiles.allSatisfy(\.isStaged)
                    Button(allStaged ? "Unstage All" : "Stage All") {
                        vm.setStaging(!allStaged, for: vm.changedFiles)
                    }
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                    .disabled(vm.changedFiles.isEmpty)

                    Divider()

                    Button("Toggle Terminal Panel") {
                        vm.toggleTerminalPanel()
                    }
                    .keyboardShortcut("j", modifiers: .command)
                }
            }

            // Terminal menu (custom)
            CommandMenu("Terminal") {
                Button("New Terminal") {
                    appState.selectedViewModel?.createTerminal()
                }
                .keyboardShortcut("t", modifiers: .command)
                .disabled(appState.selectedViewModel == nil)

                Button("New Terminal in Panel") {
                    appState.selectedViewModel?.createTerminalInPanel()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .disabled(appState.selectedViewModel == nil)

                Divider()

                let items = QuickLaunchItem.loadItems().filter { !$0.isPlainTerminal }
                ForEach(items) { item in
                    Button("Launch \(item.name)") {
                        appState.selectedViewModel?.launchQuickItem(item)
                    }
                }

                if !items.isEmpty {
                    Divider()
                }

                Button("Close Terminal") {
                    if let vm = appState.selectedViewModel,
                       let terminal = vm.selectedTerminal {
                        vm.closeTerminal(terminal)
                    }
                }
                .disabled(appState.selectedViewModel?.selectedTerminal == nil)
            }
        }

        Settings {
            SettingsView()
        }
    }
}
