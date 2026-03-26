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

    /// Check if the CLI tool is available on this system
    static func isInstalled(_ program: TerminalProgram) -> Bool {
        guard program != .shell else { return true }
        let cmd = program.command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["which", cmd]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// All known AI agent programs
    static let aiPrograms: [TerminalProgram] = [.claude, .codex, .opencode]
}

enum TerminalActivityState {
    case loading
    case busy
    case idle
}
