import SwiftUI

struct DiffLineView: View {
    let line: DiffLine
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Old line number gutter
            Text(line.oldLineNumber.map(String.init) ?? "")
                .frame(width: compact ? 36 : 44, alignment: .trailing)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
                .padding(.trailing, 4)

            // New line number gutter (unified mode only)
            if !compact {
                Text(line.newLineNumber.map(String.init) ?? "")
                    .frame(width: 44, alignment: .trailing)
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 4)
            }

            // Divider
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1)

            // Prefix (+/-/space)
            Text(line.type.prefix)
                .font(.body.monospaced())
                .foregroundStyle(prefixColor)
                .frame(width: 20, alignment: .center)

            // Content
            Text(line.content)
                .font(.body.monospaced())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
        }
        .padding(.vertical, 0.5)
        .background(line.type.backgroundColor)
    }

    private var prefixColor: Color {
        switch line.type {
        case .addition: .green
        case .deletion: .red
        case .context: .secondary
        }
    }
}
