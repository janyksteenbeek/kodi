import SwiftUI

struct QuickLaunchItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var command: String
    var arguments: String
    var icon: String
    var color: String
    var isCustomImage: Bool = false

    var isPlainTerminal: Bool { command.isEmpty }

    var displayColor: Color {
        switch color {
        case "blue": .blue
        case "orange": .orange
        case "green": .green
        case "purple": .purple
        case "red": .red
        case "pink": .pink
        case "yellow": .yellow
        case "teal": .teal
        default: .gray
        }
    }

    /// All possible quick launch items (including ones that may not be installed)
    static let allKnownItems: [QuickLaunchItem] = [
        QuickLaunchItem(name: "Terminal", command: "", arguments: "", icon: "terminal", color: "gray"),
        item(for: .claude),
        item(for: .codex),
        item(for: .opencode),
    ]

    /// Create a QuickLaunchItem from a TerminalProgram
    static func item(for program: TerminalProgram) -> QuickLaunchItem {
        QuickLaunchItem(
            name: program.displayName,
            command: program.command,
            arguments: "",
            icon: program.icon,
            color: colorString(for: program),
            isCustomImage: program.isCustomImage
        )
    }

    private static func colorString(for program: TerminalProgram) -> String {
        switch program {
        case .shell: "gray"
        case .claude: "orange"
        case .codex: "green"
        case .opencode: "blue"
        }
    }

    /// Detect installed tools and return only available items
    static func detectInstalledItems() -> [QuickLaunchItem] {
        var items: [QuickLaunchItem] = [
            QuickLaunchItem(name: "Terminal", command: "", arguments: "", icon: "terminal", color: "gray")
        ]
        for program in TerminalProgram.aiPrograms {
            if TerminalProgram.isInstalled(program) {
                items.append(item(for: program))
            }
        }
        return items
    }

    static func loadItems() -> [QuickLaunchItem] {
        guard let data = UserDefaults.standard.data(forKey: "quickLaunchItems"),
              let items = try? JSONDecoder().decode([QuickLaunchItem].self, from: data) else {
            // First launch: auto-detect installed tools
            let detected = detectInstalledItems()
            saveItems(detected)
            return detected
        }
        return items
    }

    static func saveItems(_ items: [QuickLaunchItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "quickLaunchItems")
        }
    }
}
