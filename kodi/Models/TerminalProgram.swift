import SwiftUI

enum TerminalProgram: String, Codable {
    case shell
    case claude
    case codex
    case opencode

    var displayName: String {
        switch self {
        case .shell: "Terminal"
        case .claude: "Claude"
        case .codex: "Codex"
        case .opencode: "OpenCode"
        }
    }

    var icon: String {
        switch self {
        case .shell: "terminal"
        case .claude: "ClaudeLogo"
        case .codex: "OpenAILogo"
        case .opencode: "OpenCodeLogo"
        }
    }

    var isCustomImage: Bool {
        switch self {
        case .shell: false
        case .claude, .codex, .opencode: true
        }
    }

    var color: Color {
        switch self {
        case .shell: .gray
        case .claude: .orange
        case .codex: .green
        case .opencode: .blue
        }
    }

    var command: String {
        switch self {
        case .shell: ""
        case .claude: "claude"
        case .codex: "codex"
        case .opencode: "opencode"
        }
    }

    static func detect(from command: String) -> TerminalProgram {
        let cmd = command.lowercased().trimmingCharacters(in: .whitespaces)
        if cmd == "claude" || cmd.hasPrefix("claude ") { return .claude }
        if cmd == "codex" || cmd.hasPrefix("codex ") { return .codex }
        if cmd == "opencode" || cmd.hasPrefix("opencode ") { return .opencode }
        return .shell
    }

    /// Common directories where CLI tools are installed (not in sandboxed app PATH)
    private static var searchPaths: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(home)/.local/bin",
            "\(home)/.opencode/bin",
            "\(home)/.bun/bin",
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
        ]
    }

    /// Check if the CLI tool is available on this system
    static func isInstalled(_ program: TerminalProgram) -> Bool {
        guard program != .shell else { return true }
        let cmd = program.command
        let fm = FileManager.default
        // Check common install locations directly (sandboxed apps have limited PATH)
        for dir in searchPaths {
            let fullPath = "\(dir)/\(cmd)"
            if fm.isExecutableFile(atPath: fullPath) {
                return true
            }
        }
        return false
    }

    /// All known AI agent programs
    static let aiPrograms: [TerminalProgram] = [.claude, .codex, .opencode]
}

enum TerminalActivityState {
    case loading
    case busy
    case idle
}
