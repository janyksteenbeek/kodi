import SwiftUI

struct UnifiedDiffView: View {
    let diff: DiffResult

    private var fileExtension: String {
        URL(fileURLWithPath: diff.filePath).pathExtension
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(diff.hunks) { hunk in
                // Hunk header
                Text(hunk.header)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.blue.opacity(0.06))

                // Lines
                ForEach(hunk.lines) { line in
                    DiffLineView(line: line, fileExtension: fileExtension)
                }
            }
        }
    }
}
