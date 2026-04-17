import SwiftUI

struct DiffLineView: View {
    let line: DiffLine
    var compact: Bool = false
    var fileExtension: String = ""

    @AppStorage("diffFontSize") private var fontSize = 12.0
    @AppStorage("showLineNumbers") private var showLineNumbers = true
    @AppStorage("diffTabWidth") private var tabWidth = 4
    @AppStorage("diffShowWhitespace") private var showWhitespace = false
    @AppStorage("diffWordWrap") private var wordWrap = true

    var body: some View {
        HStack(spacing: 0) {
            if showLineNumbers {
                // Old line number gutter
                Text(line.oldLineNumber.map(String.init) ?? "")
                    .frame(width: compact ? 36 : 44, alignment: .trailing)
                    .font(.system(size: max(fontSize - 2, 8)).monospaced())
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 4)

                // New line number gutter (unified mode only)
                if !compact {
                    Text(line.newLineNumber.map(String.init) ?? "")
                        .frame(width: 44, alignment: .trailing)
                        .font(.system(size: max(fontSize - 2, 8)).monospaced())
                        .foregroundStyle(.tertiary)
                        .padding(.trailing, 4)
                }

                // Divider
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1)
            }

            // Prefix (+/-/space)
            Text(line.type.prefix)
                .font(.system(size: fontSize).monospaced())
                .foregroundStyle(prefixColor)
                .frame(width: 20, alignment: .center)

            // Content
            if showWhitespace {
                whitespaceHighlightedContent
            } else {
                Text(SyntaxHighlighter.highlight(displayContent, fileExtension: fileExtension))
                    .font(.system(size: fontSize).monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(wordWrap ? nil : 1)
                    .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 0.5)
        .background(line.type.backgroundColor)
    }

    private var displayContent: String {
        let spaces = String(repeating: " ", count: tabWidth)
        return line.content.replacingOccurrences(of: "\t", with: spaces)
    }

    private var whitespaceHighlightedContent: some View {
        let content = displayContent
        let trimmed = content.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        let trailing = String(content.dropFirst(trimmed.count))

        return HStack(spacing: 0) {
            Text(SyntaxHighlighter.highlight(trimmed, fileExtension: fileExtension))
                .font(.system(size: fontSize).monospaced())
            if !trailing.isEmpty {
                Text(trailing)
                    .font(.system(size: fontSize).monospaced())
                    .background(Color.red.opacity(0.15))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(wordWrap ? nil : 1)
        .padding(.trailing, 8)
    }

    private var prefixColor: Color {
        switch line.type {
        case .addition: .green
        case .deletion: .red
        case .context: .secondary
        }
    }
}
