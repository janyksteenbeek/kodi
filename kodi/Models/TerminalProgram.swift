import SwiftUI

enum TerminalProgram: String, Codable {
    case shell
    case claude
    case codex

    var displayName: String {
        switch self {
        case .shell: "Terminal"
        case .claude: "Claude"
        case .codex: "Codex"
        }
    }

    var icon: String {
        switch self {
        case .shell: "terminal"
        case .claude: "ClaudeLogo"
        case .codex: "OpenAILogo"
        }
    }

    var isCustomImage: Bool {
        switch self {
        case .shell: false
        case .claude, .codex: true
        }
    }

    var color: Color {
        switch self {
        case .shell: .gray
        case .claude: .orange
        case .codex: .green
        }
    }

    static func detect(from command: String) -> TerminalProgram {
        let cmd = command.lowercased().trimmingCharacters(in: .whitespaces)
        if cmd == "claude" || cmd.hasPrefix("claude ") { return .claude }
        if cmd == "codex" || cmd.hasPrefix("codex ") { return .codex }
        return .shell
    }
}

enum TerminalActivityState {
    case loading  // Quick launch started, program not yet loaded
    case busy     // Program actively generating output
    case idle     // Waiting for input
}
