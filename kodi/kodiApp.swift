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
            CommandGroup(after: .newItem) {
                Button("Add Repository…") {
                    appState.addRepository()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
            CommandGroup(after: .toolbar) {
                if let vm = appState.selectedViewModel {
                    Button("Refresh") {
                        Task { await vm.refresh() }
                    }
                    .keyboardShortcut("r", modifiers: .command)

                    let allStaged = vm.changedFiles.allSatisfy(\.isStaged)
                    Button(allStaged ? "Unstage All" : "Stage All") {
                        vm.setStaging(!allStaged, for: vm.changedFiles)
                    }
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                    .disabled(vm.changedFiles.isEmpty)

                    Divider()

                    Button("New Terminal") {
                        vm.createTerminal()
                    }
                    .keyboardShortcut("t", modifiers: [.control, .shift])
                }
            }
        }

        Settings {
            SettingsView()
        }
    }
}
