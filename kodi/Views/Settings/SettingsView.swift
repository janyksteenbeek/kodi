import SwiftUI
import UserNotifications

private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
            AppearanceSettingsTab()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            EditorSettingsTab()
                .tabItem { Label("Editor", systemImage: "curlybraces") }
            CodeReviewSettingsTab()
                .tabItem { Label("Code Review", systemImage: "doc.text.magnifyingglass") }
            TerminalSettingsTab()
                .tabItem { Label("Terminal", systemImage: "terminal") }
            AISettingsTab()
                .tabItem { Label("AI & Agents", systemImage: "cpu") }
            QuickLaunchSettingsTab()
                .tabItem { Label("Quick Launch", systemImage: "sparkle") }
            GitSettingsTab()
                .tabItem { Label("Git", systemImage: "arrow.triangle.branch") }
            ViewSettingsTab()
                .tabItem { Label("Layout", systemImage: "rectangle.split.2x1") }
        }
        .frame(width: 620, height: 500)
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("reopenLastRepo") private var reopenLastRepo = true
    @AppStorage("confirmBeforeClose") private var confirmBeforeClose = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $reopenLastRepo) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reopen last repositories")
                        Text("Restore previously open repositories when launching Kodi.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle(isOn: $confirmBeforeClose) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confirm before closing")
                        Text("Ask for confirmation when closing a repository with running terminals.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Startup & Window")
            }

            Section {
                Toggle(isOn: $autoRefresh) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-refresh")
                        Text("Automatically refresh the file list when changes are detected on disk.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("File Watching")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remove all saved preferences and restore defaults. Your repositories will not be affected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Reset All Settings…", role: .destructive) {
                        let domain = Bundle.main.bundleIdentifier!
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                    }
                }
            } header: {
                Text("Reset")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Appearance

private struct AppearanceSettingsTab: View {
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("sidebarWidth") private var sidebarWidth = 260.0
@AppStorage("showFileIcons") private var showFileIcons = true

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $appColorScheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            } header: {
                Text("Theme")
            } footer: {
                Text("Override the system appearance for Kodi. Requires restart to take full effect.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
Toggle(isOn: $showFileIcons) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show file type icons")
                        Text("Display colored icons based on file extension in the sidebar.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Interface")
            }

            Section {
                HStack {
                    Text("Default Sidebar Width")
                    Spacer()
                    TextField("", value: $sidebarWidth, format: .number)
                        .frame(width: 50)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $sidebarWidth, in: 200...400, step: 10)
                        .labelsHidden()
                    Text("pt")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Sidebar")
            } footer: {
                Text("The default width of the sidebar when opening a new window.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Editor

private struct EditorSettingsTab: View {
    @AppStorage("editorFontSize") private var fontSize = 12.0
    @AppStorage("editorThemeOverride") private var themeOverride = "system"
    @AppStorage("editorShowMinimap") private var showMinimap = false
    @AppStorage("editorShowGutter") private var showGutter = true
    @AppStorage("editorShowFoldingRibbon") private var showFoldingRibbon = true
    @AppStorage("editorWrapLines") private var wrapLines = true
    @AppStorage("editorTabWidth") private var tabWidth = 4
    @AppStorage("editorIndentWithTabs") private var indentWithTabs = false
    @AppStorage("editorLineHeight") private var lineHeight = 1.2
    @AppStorage("editorLetterSpacing") private var letterSpacing = 1.0
    @AppStorage("editorBracketEmphasis") private var bracketEmphasis = "flash"
    @AppStorage("editorShowReformattingGuide") private var showReformattingGuide = false
    @AppStorage("editorReformatColumn") private var reformatColumn = 80
    @AppStorage("editorShowInvisibleSpaces") private var showInvisibleSpaces = false
    @AppStorage("editorShowInvisibleTabs") private var showInvisibleTabs = false
    @AppStorage("editorShowInvisibleLineEndings") private var showInvisibleLineEndings = false

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $themeOverride) {
                    Text("Follow System").tag("system")
                    Text("Always Light").tag("light")
                    Text("Always Dark").tag("dark")
                }
            } header: {
                Text("Theme")
            } footer: {
                Text("Override the editor color scheme independently from the app appearance.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                HStack {
                    Text("Font Size")
                    Spacer()
                    TextField("", value: $fontSize, format: .number)
                        .frame(width: 45)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $fontSize, in: 9...36, step: 1)
                        .labelsHidden()
                    Text("pt")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Line Height")
                    Spacer()
                    TextField("", value: $lineHeight, format: .number.precision(.fractionLength(1)))
                        .frame(width: 45)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $lineHeight, in: 1.0...2.0, step: 0.1)
                        .labelsHidden()
                    Text("×")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Letter Spacing")
                    Spacer()
                    TextField("", value: $letterSpacing, format: .number.precision(.fractionLength(1)))
                        .frame(width: 45)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $letterSpacing, in: 0.5...2.0, step: 0.1)
                        .labelsHidden()
                    Text("×")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Font & Spacing")
            }

            Section {
                HStack {
                    Text("Tab Width")
                    Spacer()
                    TextField("", value: $tabWidth, format: .number)
                        .frame(width: 40)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $tabWidth, in: 1...8, step: 1)
                        .labelsHidden()
                    Text("spaces")
                        .foregroundStyle(.secondary)
                }
                Picker("Indent Using", selection: $indentWithTabs) {
                    Text("Spaces").tag(false)
                    Text("Tabs").tag(true)
                }
                Toggle(isOn: $wrapLines) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wrap lines")
                        Text("Soft-wrap long lines instead of horizontal scrolling.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Picker("Bracket Emphasis", selection: $bracketEmphasis) {
                    Text("Flash").tag("flash")
                    Text("Bordered").tag("bordered")
                    Text("Underline").tag("underline")
                    Text("Off").tag("off")
                }
            } header: {
                Text("Editing")
            }

            Section {
                Toggle(isOn: $showMinimap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show minimap")
                        Text("Display a minimap of the file on the right side of the editor.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle(isOn: $showGutter) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show line numbers")
                        Text("Display line numbers in the editor gutter.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle(isOn: $showFoldingRibbon) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show folding ribbon")
                        Text("Show code folding controls in the gutter.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle(isOn: $showReformattingGuide) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show column guide")
                        Text("Display a vertical line at the specified column.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if showReformattingGuide {
                    HStack {
                        Text("Guide Column")
                        Spacer()
                        TextField("", value: $reformatColumn, format: .number)
                            .frame(width: 45)
                            .multilineTextAlignment(.trailing)
                        Stepper("", value: $reformatColumn, in: 40...200, step: 10)
                            .labelsHidden()
                    }
                }
            } header: {
                Text("Display")
            }

            Section {
                Toggle("Spaces", isOn: $showInvisibleSpaces)
                Toggle("Tabs", isOn: $showInvisibleTabs)
                Toggle("Line Endings", isOn: $showInvisibleLineEndings)
            } header: {
                Text("Invisible Characters")
            } footer: {
                Text("Show symbols for whitespace and line ending characters.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - AI & Agents

private struct AISettingsTab: View {
    @AppStorage("aiAutoApprove") private var autoApprove = false
    @AppStorage("aiNotifyOnComplete") private var notifyOnComplete = false
    @AppStorage("claudeArgs") private var claudeArgs = ""
    @AppStorage("codexArgs") private var codexArgs = ""
    @AppStorage("opencodeArgs") private var opencodeArgs = ""
    @State private var installedTools: [TerminalProgram] = []

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(TerminalProgram.aiPrograms, id: \.self) { program in
                            HStack(spacing: 6) {
                                Image(program.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 14, height: 14)
                                    .foregroundStyle(program.color)
                                Text(program.displayName)
                                    .font(.callout)
                                Spacer()
                                if installedTools.contains(program) {
                                    Text("Installed")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else {
                                    Text("Not found")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
                Button("Detect Installed Tools") {
                    detectTools()
                }
            } header: {
                Text("Detected Tools")
            } footer: {
                Text("Scans your PATH for known AI coding agents. Detected tools are added to Quick Launch automatically.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                Toggle(isOn: $notifyOnComplete) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notify when agent finishes")
                        Text("Show a system notification when an AI agent completes a task.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: notifyOnComplete) { _, enabled in
                    if enabled { requestNotificationPermission() }
                }
                Toggle(isOn: $autoApprove) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-approve file changes")
                        Text("Automatically accept file modifications suggested by AI agents. Use with caution.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Behavior")
            }

            Section {
                HStack {
                    Image("ClaudeLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.orange)
                    TextField("Claude arguments", text: $claudeArgs, prompt: Text("e.g. --model opus"))
                }
                HStack {
                    Image("OpenAILogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.green)
                    TextField("Codex arguments", text: $codexArgs, prompt: Text("e.g. --model gpt-4"))
                }
                HStack {
                    Image("OpenCodeLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.blue)
                    TextField("OpenCode arguments", text: $opencodeArgs, prompt: Text("Optional flags"))
                }
            } header: {
                Text("Default Arguments")
            } footer: {
                Text("These arguments are appended when launching via Quick Launch. Override per-item in Quick Launch settings.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .onAppear { detectTools() }
    }

    private func detectTools() {
        installedTools = TerminalProgram.aiPrograms.filter { TerminalProgram.isInstalled($0) }

        // Also update quick launch items with newly detected tools
        var currentItems = QuickLaunchItem.loadItems()
        for program in installedTools {
            let item = QuickLaunchItem.item(for: program)
            if !currentItems.contains(where: { $0.command == item.command }) {
                currentItems.append(item)
            }
        }
        QuickLaunchItem.saveItems(currentItems)
        NotificationCenter.default.post(name: .quickLaunchItemsDidChange, object: nil)
    }
}

// MARK: - Terminal

private struct TerminalSettingsTab: View {
    @AppStorage("terminalFontSize") private var terminalFontSize = 13.0
    @AppStorage("terminalShell") private var terminalShell = ""
    @AppStorage("terminalActivityTracking") private var activityTracking = true
    @AppStorage("terminalIdleTimeout") private var idleTimeout = 2.0

    private let availableShells = [
        ("", "System Default"),
        ("/bin/zsh", "zsh"),
        ("/bin/bash", "bash"),
        ("/bin/sh", "sh"),
    ]

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Font Size")
                    Spacer()
                    TextField("", value: $terminalFontSize, format: .number)
                        .frame(width: 45)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $terminalFontSize, in: 9...24, step: 1)
                        .labelsHidden()
                    Text("pt")
                        .foregroundStyle(.secondary)
                }
                Text("Applies to new terminal sessions. Existing terminals keep their current size.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Appearance")
            }

            Section {
                Picker("Default Shell", selection: $terminalShell) {
                    ForEach(availableShells, id: \.0) { shell in
                        Text(shell.1).tag(shell.0)
                    }
                }
                if terminalShell.isEmpty {
                    let systemShell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Using system shell: **\(systemShell)**")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            } header: {
                Text("Shell")
            } footer: {
                Text("The shell used when opening new terminal sessions and running quick launch commands.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                Toggle(isOn: $activityTracking) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activity Detection")
                        Text("Show real-time loading, busy and idle indicators for Claude, Codex and other recognized tools in the sidebar.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if activityTracking {
                    HStack {
                        Text("Idle Timeout")
                        Spacer()
                        TextField("", value: $idleTimeout, format: .number)
                            .frame(width: 40)
                            .multilineTextAlignment(.trailing)
                        Stepper("", value: $idleTimeout, in: 1...15, step: 0.5)
                            .labelsHidden()
                        Text("sec")
                            .foregroundStyle(.secondary)
                    }
                    Text("How long to wait after the last activity before marking a tool as idle. Increase if the indicator flickers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Smart Terminals")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Git

private struct GitSettingsTab: View {
    @AppStorage("gitAuthorName") private var gitAuthorName = ""
    @AppStorage("gitAuthorEmail") private var gitAuthorEmail = ""
    @AppStorage("autoStageOnCommit") private var autoStageOnCommit = false

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $gitAuthorName, prompt: Text("Uses git config value"))
                TextField("Email", text: $gitAuthorEmail, prompt: Text("Uses git config value"))
            } header: {
                Text("Commit Author")
            } footer: {
                Text("Override the author name and email for commits. Leave empty to use values from your git configuration.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                Toggle(isOn: $autoStageOnCommit) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-stage on commit")
                        Text("Automatically stage all tracked modified files when committing.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Behavior")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Code Review

private struct CodeReviewSettingsTab: View {
    @AppStorage("defaultDiffMode") private var defaultDiffMode = "unified"
    @AppStorage("diffFontSize") private var diffFontSize = 12.0
    @AppStorage("diffContextLines") private var diffContextLines = 3
    @AppStorage("showLineNumbers") private var showLineNumbers = true
    @AppStorage("diffWordWrap") private var diffWordWrap = true
    @AppStorage("diffShowWhitespace") private var showWhitespace = false
    @AppStorage("diffTabWidth") private var tabWidth = 4

    var body: some View {
        Form {
            Section {
                Picker("Default Mode", selection: $defaultDiffMode) {
                    Label("Unified", systemImage: "text.alignleft").tag("unified")
                    Label("Side by Side", systemImage: "rectangle.split.2x1").tag("sideBySide")
                }
            } header: {
                Text("Layout")
            } footer: {
                Text("How diffs are displayed when opening a file. You can always switch per file using the toolbar.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                HStack {
                    Text("Font Size")
                    Spacer()
                    TextField("", value: $diffFontSize, format: .number)
                        .frame(width: 45)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $diffFontSize, in: 9...24, step: 1)
                        .labelsHidden()
                    Text("pt")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Tab Width")
                    Spacer()
                    TextField("", value: $tabWidth, format: .number)
                        .frame(width: 40)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $tabWidth, in: 1...8, step: 1)
                        .labelsHidden()
                    Text("spaces")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Context Lines")
                    Spacer()
                    TextField("", value: $diffContextLines, format: .number)
                        .frame(width: 40)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $diffContextLines, in: 0...20, step: 1)
                        .labelsHidden()
                }
            } header: {
                Text("Text")
            } footer: {
                Text("Font size applies to diff content. Context lines control how many unchanged lines surround each change.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                Toggle(isOn: $showLineNumbers) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show line numbers")
                        Text("Display line numbers in the gutter of diff views.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle(isOn: $diffWordWrap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Word wrap")
                        Text("Wrap long lines instead of horizontal scrolling.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle(isOn: $showWhitespace) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show whitespace changes")
                        Text("Highlight spaces, tabs and trailing whitespace in diffs.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Display")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - View

private struct ViewSettingsTab: View {
    @AppStorage("defaultTerminalPanelMode") private var defaultTerminalPanelMode = "right"
    @AppStorage("defaultTerminalPaneLayout") private var defaultTerminalPaneLayout = "Side by Side"
    @AppStorage("primaryPanel") private var primaryPanel = "terminal"
    @AppStorage("terminalClickAction") private var terminalClickAction = "panel"
    @AppStorage("terminalOpenOnLaunch") private var terminalOpenOnLaunch = false
    @AppStorage("groupByFolder") private var groupByFolder = true
    @AppStorage("showUntrackedFiles") private var showUntrackedFiles = true

    var body: some View {
        Form {
            Section {
                Picker("Split Position", selection: $defaultTerminalPanelMode) {
                    Label("Bottom", systemImage: "rectangle.split.1x2").tag("bottom")
                    Label("Right", systemImage: "rectangle.split.2x1").tag("right")
                }
                .pickerStyle(.segmented)
                Picker("Pane Layout", selection: $defaultTerminalPaneLayout) {
                    Label("Side by Side", systemImage: "rectangle.split.3x1").tag("Side by Side")
                    Label("Stacked", systemImage: "rectangle.split.1x2").tag("Stacked")
                    Label("Grid", systemImage: "square.grid.2x2").tag("Grid")
                }
                .pickerStyle(.segmented)
                Picker("Primary Panel", selection: $primaryPanel) {
                    Label("Diff", systemImage: "doc.text").tag("diff")
                    Label("Terminal", systemImage: "terminal").tag("terminal")
                }
                .pickerStyle(.segmented)
                Picker("Click Action", selection: $terminalClickAction) {
                    Text("Open in Panel").tag("panel")
                    Text("Open Full Screen").tag("fullscreen")
                }
                .pickerStyle(.segmented)
                Toggle(isOn: $terminalOpenOnLaunch) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Open terminal on launch")
                        Text("Automatically open a terminal panel when opening a repository.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Terminal Panel")
            } footer: {
                Text("Primary panel determines which content gets the larger area in split view. Click action controls what happens when you select a terminal in the sidebar.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
                Toggle(isOn: $groupByFolder) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Group files by folder")
                        Text("Show changed files in a folder tree instead of a flat list.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle(isOn: $showUntrackedFiles) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show untracked files")
                        Text("Include new files that haven't been added to git yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Sidebar")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Quick Launch

private struct QuickLaunchSettingsTab: View {
    @State private var items = QuickLaunchItem.loadItems()
    @State private var editingItem: QuickLaunchItem?

    private let availableIcons = [
        "terminal", "sparkle", "wand.and.stars", "bolt", "cpu",
        "chevron.left.forwardslash.chevron.right", "hammer", "wrench",
        "ant", "ladybug", "puzzlepiece", "gear",
    ]

    private let availableColors = [
        ("gray", "Gray"), ("blue", "Blue"), ("orange", "Orange"),
        ("green", "Green"), ("purple", "Purple"), ("red", "Red"),
        ("pink", "Pink"), ("teal", "Teal"), ("yellow", "Yellow"),
    ]

    var body: some View {
        Form {
            Section {
                ForEach($items) { $item in
                    HStack(spacing: 10) {
                        if item.isCustomImage {
                            Image(item.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                                .foregroundStyle(item.displayColor)
                        } else {
                            Image(systemName: item.icon)
                                .foregroundStyle(item.displayColor)
                                .frame(width: 18)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.callout.weight(.medium))
                            if !item.command.isEmpty {
                                Text(item.arguments.isEmpty ? item.command : "\(item.command) \(item.arguments)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Plain shell session")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Spacer()

                        Button {
                            editingItem = item
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)

                        Button(role: .destructive) {
                            items.removeAll { $0.id == item.id }
                            save()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Launch Items")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("These appear in the sidebar and on the main screen for quick access. Claude and Codex are automatically detected for activity tracking.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Button {
                        let newItem = QuickLaunchItem(
                            name: "New Item",
                            command: "",
                            arguments: "",
                            icon: "terminal",
                            color: "gray"
                        )
                        items.append(newItem)
                        editingItem = newItem
                        save()
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                }
            }

            Section {
                Button("Restore Defaults") {
                    items = QuickLaunchItem.detectInstalledItems()
                    save()
                }
                Text("Reset quick launch items to Terminal, Claude and Codex.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Reset")
            }
        }
        .formStyle(.grouped)
        .sheet(item: $editingItem) { item in
            QuickLaunchEditSheet(
                item: item,
                availableIcons: availableIcons,
                availableColors: availableColors
            ) { updated in
                if let idx = items.firstIndex(where: { $0.id == updated.id }) {
                    items[idx] = updated
                    save()
                }
            }
        }
    }

    private func save() {
        QuickLaunchItem.saveItems(items)
        NotificationCenter.default.post(name: .quickLaunchItemsDidChange, object: nil)
    }
}

private struct QuickLaunchEditSheet: View {
    @State var item: QuickLaunchItem
    let availableIcons: [String]
    let availableColors: [(String, String)]
    let onSave: (QuickLaunchItem) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Name", text: $item.name)
                    TextField("Command", text: $item.command, prompt: Text("e.g. claude, codex"))
                    TextField("Arguments", text: $item.arguments, prompt: Text("Optional flags"))
                } header: {
                    Text("Command")
                } footer: {
                    Text("Leave command empty for a plain shell session.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Section("Appearance") {
                    Picker("Icon", selection: $item.icon) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Label(icon, systemImage: icon).tag(icon)
                        }
                    }

                    Picker("Color", selection: $item.color) {
                        ForEach(availableColors, id: \.0) { color in
                            Text(color.1).tag(color.0)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    onSave(item)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 380, height: 340)
    }
}
