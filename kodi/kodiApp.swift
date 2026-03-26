import SwiftUI

@main
struct kodiApp: App {
    @State private var appState = AppState()
    @FocusedValue(\.repositoryViewModel) private var focusedVM

    var body: some Scene {
        WindowGroup(for: UUID.self) { $repoID in
            RepoWindowContent(repoID: $repoID, appState: appState)
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
            }

            // View menu
            CommandGroup(after: .toolbar) {
                if let vm = focusedVM {
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

            // Git menu
            CommandMenu("Git") {
                Button("Commit") {
                    if let vm = focusedVM {
                        Task { await vm.commit() }
                    }
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(focusedVM == nil)

                Divider()

                Button("Stage All") {
                    if let vm = focusedVM {
                        vm.setStaging(true, for: vm.changedFiles)
                    }
                }
                .disabled(focusedVM?.changedFiles.isEmpty ?? true)

                Button("Unstage All") {
                    if let vm = focusedVM {
                        vm.setStaging(false, for: vm.changedFiles)
                    }
                }
                .disabled(focusedVM?.changedFiles.isEmpty ?? true)

                Divider()

                if let vm = focusedVM, vm.hasRemote {
                    Button("Push") {
                        Task { await vm.push() }
                    }
                    .disabled(vm.isSyncing)

                    Button("Pull") {
                        Task { await vm.pull() }
                    }
                    .disabled(vm.isSyncing)
                }
            }

            // Terminal menu
            CommandMenu("Terminal") {
                Button("New Terminal") {
                    focusedVM?.createTerminalInPanel()
                }
                .keyboardShortcut("t", modifiers: .command)
                .disabled(focusedVM == nil)

                Button("New Terminal Full Screen") {
                    focusedVM?.createTerminal()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .disabled(focusedVM == nil)

                Divider()

                let items = QuickLaunchItem.loadItems().filter { !$0.isPlainTerminal }
                ForEach(items) { item in
                    Button("Launch \(item.name)") {
                        focusedVM?.launchQuickItem(item)
                    }
                }

                if !items.isEmpty {
                    Divider()
                }

                Button("Toggle Terminal Panel") {
                    focusedVM?.toggleTerminalPanel()
                }
                .keyboardShortcut("j", modifiers: .command)
                .disabled(focusedVM == nil)

                Button("Close Terminal") {
                    if let vm = focusedVM, let terminal = vm.selectedTerminal {
                        vm.closeTerminal(terminal)
                    }
                }
                .disabled(focusedVM?.selectedTerminal == nil)
            }
        }

        Settings {
            SettingsView()
        }
    }
}

private struct RepoWindowContent: View {
    @Binding var repoID: UUID?
    let appState: AppState
    @Environment(\.openWindow) private var openWindow
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("terminalOpenOnLaunch") private var terminalOpenOnLaunch = false

    private var colorScheme: ColorScheme? {
        switch appColorScheme {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    var body: some View {
        Group {
            if let id = repoID, let vm = appState.viewModel(for: id) {
                ContentView(viewModel: vm)
                    .focusedValue(\.repositoryViewModel, vm)
                    .navigationTitle(vm.repository.displayName)
                    .onAppear {
                        if terminalOpenOnLaunch && vm.terminalSessions.isEmpty {
                            vm.createTerminalInPanel()
                        }
                    }
            } else {
                WelcomeView()
            }
        }
        .preferredColorScheme(colorScheme)
        .task {
            appState.openRepositoryTab = { [openWindow] id in
                // Open new window, then merge it as a tab
                openWindow(value: id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    mergeAllWindowsAsTabs()
                }
            }
            // On first launch, open saved repos
            if repoID == nil {
                let savedIDs = appState.loadSavedRepositories()
                if let first = savedIDs.first {
                    repoID = first
                    for id in savedIDs.dropFirst() {
                        openWindow(value: id)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        mergeAllWindowsAsTabs()
                    }
                }
            }
        }
    }
}

private func mergeAllWindowsAsTabs() {
    let windows = NSApplication.shared.windows.filter { $0.isVisible && $0.tabbingIdentifier == NSApplication.shared.windows.first?.tabbingIdentifier }
    guard let primary = windows.first else { return }
    for window in windows.dropFirst() {
        if window.tabGroup != primary.tabGroup {
            primary.addTabbedWindow(window, ordered: .above)
        }
    }
}

private struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.tint)

            VStack(spacing: 4) {
                Text("Kodi")
                    .font(.largeTitle.weight(.bold))
                Text("The Agentic IDE")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Button {
                appState.addRepository()
            } label: {
                Label("Open Repository…", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)

            Text("⌘O")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
