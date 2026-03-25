import SwiftUI

struct ChangedFile: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let status: FileStatus
    var isStaged: Bool
    var oldPath: String?

    var fileName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    var directory: String {
        let dir = URL(fileURLWithPath: path).deletingLastPathComponent().relativePath
        return dir == "." ? "" : dir
    }

    enum FileStatus: String, CaseIterable {
        case modified = "M"
        case added = "A"
        case deleted = "D"
        case renamed = "R"
        case untracked = "?"
        case copied = "C"

        var displayName: String {
            switch self {
            case .modified: "Modified"
            case .added: "Added"
            case .deleted: "Deleted"
            case .renamed: "Renamed"
            case .untracked: "Untracked"
            case .copied: "Copied"
            }
        }

        var sfSymbol: String {
            switch self {
            case .modified: "pencil.circle.fill"
            case .added: "plus.circle.fill"
            case .deleted: "minus.circle.fill"
            case .renamed: "arrow.right.circle.fill"
            case .untracked: "questionmark.circle.fill"
            case .copied: "doc.on.doc.fill"
            }
        }

        var color: Color {
            switch self {
            case .modified: .orange
            case .added: .green
            case .deleted: .red
            case .renamed: .blue
            case .untracked: .gray
            case .copied: .purple
            }
        }
    }
}
