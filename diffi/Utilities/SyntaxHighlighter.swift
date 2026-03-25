import SwiftUI

// Placeholder for future syntax highlighting
// Can be expanded with TreeSitter or regex-based keyword coloring
struct SyntaxHighlighter {
    static func highlight(_ code: String, fileExtension: String) -> AttributedString {
        var result = AttributedString(code)
        result.font = .body.monospaced()
        return result
    }
}
