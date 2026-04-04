import SwiftUI

struct DiffResult: Identifiable {
    let id = UUID()
    let filePath: String
    let oldPath: String?
    let hunks: [DiffHunk]
    var additions: Int {
        hunks.flatMap(\.lines).filter { $0.type == .addition }.count
    }
    var deletions: Int {
        hunks.flatMap(\.lines).filter { $0.type == .deletion }.count
    }
    var totalLines: Int {
        hunks.reduce(0) { $0 + $1.lines.count }
    }
}

struct DiffHunk: Identifiable {
    let id = UUID()
    let header: String
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let lines: [DiffLine]
}

struct DiffLine: Identifiable {
    let id = UUID()
    let type: LineType
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?

    enum LineType {
        case context
        case addition
        case deletion

        var prefix: String {
            switch self {
            case .context: " "
            case .addition: "+"
            case .deletion: "-"
            }
        }

        var backgroundColor: Color {
            switch self {
            case .context: .clear
            case .addition: .green.opacity(0.12)
            case .deletion: .red.opacity(0.12)
            }
        }
    }
}
