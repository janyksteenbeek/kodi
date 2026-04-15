import SwiftUI

class KodiAppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        appState?.isTerminating = true
        return .terminateNow
    }
}

@main
struct kodiApp: App {
    @NSApplicationDelegateAdaptor(KodiAppDelegate.self) private var appDelegate
    @State private var appState = AppState()
    @FocusedValue(\.repositoryViewModel) private var focusedVM

    init() {
        QuickLaunchItem.runInitialDetectionIfNeeded()
    }

    var body: some Scene {
        WindowGroup(for: UUID.self) { $repoID in
            RepoWindowContent(repoID: $repoID, appState: appState)
                .environment(appState)
                .onAppear {
                    appDelegate.appState = appState
                }
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

                    Button("Toggle File Inspector") {
                        vm.isInspectorVisible.toggle()
                    }
                    .keyboardShortcut("e", modifiers: [.command, .shift])

                    Button("Go to File…") {
                        vm.isGlobalSearchVisible.toggle()
                    }
                    .keyboardShortcut("f", modifiers: [.command, .shift])
                }
            }

            // File menu - Save
            CommandGroup(after: .newItem) {
                if let vm = focusedVM, vm.isEditorVisible {
                    Button("Save") {
                        if let session = vm.editorSessions.last(where: { $0.hasUnsavedChanges }) {
                            session.save()
                        }
                    }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(!vm.hasAnyUnsavedChanges)
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
                .keyboardShortcut(.delete, modifiers: .command)
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
    @State private var hostingWindow: NSWindow?

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
                    .background(WindowAccessor { window in hostingWindow = window })
                    .onAppear {
                        if terminalOpenOnLaunch && vm.terminalSessions.isEmpty {
                            vm.createTerminalInPanel()
                        }
                        appState.activate(id)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
                        guard let window = notification.object as? NSWindow,
                              window == hostingWindow else { return }
                        appState.activate(id)
                    }
            } else {
                WelcomeView()
            }
        }
        .preferredColorScheme(colorScheme)
        .onDisappear {
            if let id = repoID, !appState.isTerminating {
                appState.removeRepository(id: id)
            }
        }
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
                    let remaining = Array(savedIDs.dropFirst())
                    if !remaining.isEmpty {
                        // Wait for the primary window to appear, set it to prefer tabs,
                        // then open the rest — macOS will add them as tabs directly.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let primary = NSApp.windows.first(where: { $0.isVisible }) {
                                primary.tabbingMode = .preferred
                            }
                            for id in remaining {
                                openWindow(value: id)
                            }
                            // Safety fallback in case auto-tabbing didn't merge all
                            DispatchQueue.main.async {
                                mergeAllWindowsAsTabs()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onResolve(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { onResolve(nsView.window) }
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
        VStack(spacing: 20) {
                Spacer()
                Spacer()

                // App icon
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .shadow(color: .accentColor.opacity(0.3), radius: 20, y: 5)

                VStack(spacing: 6) {
                    Text("Kodi")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("The Agentic IDE")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                // Quick actions
                VStack(spacing: 10) {
                    Button {
                        appState.addRepository()
                    } label: {
                        Label("Open Repository…", systemImage: "folder.badge.plus")
                            .frame(width: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("⌘O")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 4)

                Spacer()

                // Footer with detected tools
                WelcomeToolsBar()
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Detected tools footer

private struct WelcomeToolsBar: View {
    @State private var tools: [(program: TerminalProgram, installed: Bool)] = []

    var body: some View {
        VStack(spacing: 8) {
            if !tools.isEmpty {
                Text("Detected on this Mac")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)

                HStack(spacing: 16) {
                    ForEach(tools, id: \.program) { tool in
                        HStack(spacing: 4) {
                            if tool.program.isCustomImage {
                                Image(tool.program.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 14, height: 14)
                                    .foregroundStyle(tool.installed ? tool.program.color : Color.gray.opacity(0.3))
                            } else {
                                Image(systemName: tool.program.icon)
                                    .font(.caption)
                                    .foregroundStyle(tool.installed ? tool.program.color : Color.gray.opacity(0.3))
                            }
                            Text(tool.program.displayName)
                                .font(.caption)
                                .foregroundStyle(tool.installed ? .secondary : .tertiary)
                        }
                    }
                }
            }
        }
        .task {
            tools = TerminalProgram.aiPrograms.map { ($0, TerminalProgram.isInstalled($0)) }
        }
    }
}
