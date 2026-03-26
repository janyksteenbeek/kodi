import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
            TerminalSettingsTab()
                .tabItem { Label("Terminal", systemImage: "terminal") }
            QuickLaunchSettingsTab()
                .tabItem { Label("Quick Launch", systemImage: "sparkle") }
            GitSettingsTab()
                .tabItem { Label("Git", systemImage: "arrow.triangle.branch") }
            ViewSettingsTab()
                .tabItem { Label("View", systemImage: "eye") }
        }
        .frame(width: 500, height: 380)
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    @AppStorage("autoRefresh") private var autoRefresh = true

    var body: some View {
        Form {
            Toggle("Auto-refresh on file changes", isOn: $autoRefresh)

            Section {
                Button("Reset All Settings", role: .destructive) {
                    resetAllSettings()
                }
            }
        }
        .formStyle(.grouped)
    }

    private func resetAllSettings() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }
}

// MARK: - Terminal

private struct TerminalSettingsTab: View {
    @AppStorage("terminalFontSize") private var terminalFontSize = 13.0
    @AppStorage("terminalShell") private var terminalShell = ""

    private let availableShells = [
        ("", "System Default"),
        ("/bin/zsh", "zsh"),
        ("/bin/bash", "bash"),
        ("/bin/sh", "sh"),
    ]

    var body: some View {
        Form {
            Section("Font") {
                HStack {
                    TextField("Size", value: $terminalFontSize, format: .number)
                        .frame(width: 50)
                    Stepper("Font Size", value: $terminalFontSize, in: 9...24, step: 1)
                        .labelsHidden()
                    Text("pt")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Shell") {
                Picker("Shell", selection: $terminalShell) {
                    ForEach(availableShells, id: \.0) { shell in
                        Text(shell.1).tag(shell.0)
                    }
                }

                if terminalShell.isEmpty {
                    let systemShell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
                    Text("Using system shell: \(systemShell)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
            Section("Author") {
                TextField("Name", text: $gitAuthorName, prompt: Text("From git config"))
                TextField("Email", text: $gitAuthorEmail, prompt: Text("From git config"))
            }

            Section("Behavior") {
                Toggle("Auto-stage tracked files on commit", isOn: $autoStageOnCommit)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - View

private struct ViewSettingsTab: View {
    @AppStorage("defaultDiffMode") private var defaultDiffMode = "unified"
    @AppStorage("defaultTerminalPanelMode") private var defaultTerminalPanelMode = "bottom"
    @AppStorage("primaryPanel") private var primaryPanel = "terminal"
    @AppStorage("groupByFolder") private var groupByFolder = true

    var body: some View {
        Form {
            Section("Diff") {
                Picker("Default Diff Mode", selection: $defaultDiffMode) {
                    Label("Unified", systemImage: "text.alignleft").tag("unified")
                    Label("Side by Side", systemImage: "rectangle.split.2x1").tag("sideBySide")
                }
            }

            Section("Terminal Panel") {
                Picker("Default Position", selection: $defaultTerminalPanelMode) {
                    Label("Bottom", systemImage: "rectangle.split.1x2").tag("bottom")
                    Label("Right", systemImage: "rectangle.split.2x1").tag("right")
                }
                Picker("Primary Panel", selection: $primaryPanel) {
                    Label("Diff", systemImage: "doc.text").tag("diff")
                    Label("Terminal", systemImage: "terminal").tag("terminal")
                }
            }

            Section("Sidebar") {
                Toggle("Group files by folder", isOn: $groupByFolder)
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
                        Image(systemName: item.icon)
                            .foregroundStyle(item.displayColor)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.callout.weight(.medium))
                            if !item.command.isEmpty {
                                Text(item.arguments.isEmpty ? item.command : "\(item.command) \(item.arguments)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Plain shell")
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
                .padding(.top, 4)
            }

            Section("Reset") {
                Button("Restore Defaults") {
                    items = QuickLaunchItem.defaultItems
                    save()
                }
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
                TextField("Name", text: $item.name)
                TextField("Command", text: $item.command, prompt: Text("e.g. claude, codex"))
                TextField("Arguments", text: $item.arguments, prompt: Text("Optional flags"))

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
            }
            .padding()
        }
        .frame(width: 350, height: 320)
    }
}
