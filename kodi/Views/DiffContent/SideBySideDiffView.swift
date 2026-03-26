import SwiftUI

struct SideBySideDiffView: View {
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

                let pairs = pairLines(hunk.lines)
                ForEach(pairs.indices, id: \.self) { index in
                    HStack(spacing: 0) {
                        // Left side (old)
                        if let left = pairs[index].left {
                            DiffLineView(line: left, compact: true, fileExtension: fileExtension)
                                .frame(maxWidth: .infinity)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 20)
                        }

                        Rectangle()
                            .fill(.quaternary)
                            .frame(width: 1)

                        // Right side (new)
                        if let right = pairs[index].right {
                            DiffLineView(line: right, compact: true, fileExtension: fileExtension)
                                .frame(maxWidth: .infinity)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 20)
                        }
                    }
                }
            }
        }
    }

    private func pairLines(_ lines: [DiffLine]) -> [(left: DiffLine?, right: DiffLine?)] {
        var pairs: [(left: DiffLine?, right: DiffLine?)] = []
        var deletions: [DiffLine] = []
        var additions: [DiffLine] = []

        func flushPending() {
            let count = max(deletions.count, additions.count)
            for i in 0..<count {
                pairs.append((
                    left: i < deletions.count ? deletions[i] : nil,
                    right: i < additions.count ? additions[i] : nil
                ))
            }
            deletions.removeAll()
            additions.removeAll()
        }

        for line in lines {
            switch line.type {
            case .context:
                flushPending()
                pairs.append((left: line, right: line))
            case .deletion:
                deletions.append(line)
            case .addition:
                additions.append(line)
            }
        }
        flushPending()

        return pairs
    }
}
