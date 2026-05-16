import SwiftUI

struct CommitRow: View {
    let commit: Commit
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            graphRail

            VStack(alignment: .leading, spacing: 4) {
                Text(commit.subject.isEmpty ? "(no subject)" : commit.subject)
                    .font(.system(.body, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 6) {
                    Text(commit.shortSHA)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 4))

                    Text(commit.authorName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 9)

            Spacer(minLength: 12)

            Text(commit.date, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.trailing, 14)
        }
        .contentShape(Rectangle())
    }

    private var graphRail: some View {
        ZStack {
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1.5)

            Circle()
                .fill(isSelected ? Color.accentColor : Color.secondary)
                .frame(width: 9, height: 9)
                .overlay(
                    Circle()
                        .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 2.5)
                )
        }
        .frame(width: 34)
        .frame(maxHeight: .infinity)
    }
}
