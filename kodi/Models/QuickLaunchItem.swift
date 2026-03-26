import SwiftUI

struct QuickLaunchItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var command: String
    var arguments: String
    var icon: String          // SF Symbol name OR asset image name
    var color: String
    var isCustomImage: Bool = false  // true = asset catalog image, false = SF Symbol

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
            name: "Claude",
            command: "claude",
            arguments: "",
            icon: "ClaudeLogo",
            color: "orange",
            isCustomImage: true
        ),
        QuickLaunchItem(
            name: "Codex",
            command: "codex",
            arguments: "",
            icon: "OpenAILogo",
            color: "green",
            isCustomImage: true
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
