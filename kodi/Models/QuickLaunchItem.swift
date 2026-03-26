import SwiftUI

struct QuickLaunchItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var command: String
    var arguments: String
    var icon: String
    var color: String

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

    static let defaultItems: [QuickLaunchItem] = [
        QuickLaunchItem(
            name: "Terminal",
            command: "",
            arguments: "",
            icon: "terminal",
            color: "gray"
        ),
        QuickLaunchItem(
            name: "Claude Code",
            command: "claude",
            arguments: "",
            icon: "sparkle",
            color: "orange"
        ),
        QuickLaunchItem(
            name: "Codex",
            command: "codex",
            arguments: "",
            icon: "wand.and.stars",
            color: "green"
        ),
    ]

    static func loadItems() -> [QuickLaunchItem] {
        guard let data = UserDefaults.standard.data(forKey: "quickLaunchItems"),
              let items = try? JSONDecoder().decode([QuickLaunchItem].self, from: data) else {
            return defaultItems
        }
        return items
    }

    static func saveItems(_ items: [QuickLaunchItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "quickLaunchItems")
        }
    }
}
