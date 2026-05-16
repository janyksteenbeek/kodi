import SwiftUI

struct CommitDetailSheet: View {
    let commit: Commit
    let viewModel: HistoryViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var diffs: [DiffResult] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var mode: RepositoryViewModel.DiffMode = .unified

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.fill.quaternary)

            Divider()

            content
        }
        .frame(minWidth: 900, idealWidth: 1100, minHeight: 600, idealHeight: 750)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .primaryAction) {
                Picker("Diff Mode", selection: $mode) {
                    ForEach(RepositoryViewModel.DiffMode.allCases, id: \.self) { m in
                        Image(systemName: m.icon).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .help("Toggle diff layout")
            }
        }
        .task {
            await load()
        }
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(commit.subject.isEmpty ? "(no subject)" : commit.subject)
                .font(.title3.bold())
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(commit.shortSHA)
                    .font(.callout.monospaced())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 4))
                Text(commit.authorName)
                    .font(.callout)
                Text("·").foregroundStyle(.tertiary)
                Text(commit.date, format: .dateTime.year().month().day().hour().minute())
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if !commit.body.isEmpty {
                Text(commit.body)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack {
                Spacer()
                ProgressView("Loading diff…")
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadError {
            ContentUnavailableView(
                "Couldn't load diff",
                systemImage: "exclamationmark.triangle",
                description: Text(loadError)
            )
        } else if diffs.isEmpty {
            ContentUnavailableView(
                "No changes",
                systemImage: "doc.text",
                description: Text("This commit doesn't introduce file changes.")
            )
        } else {
            DiffContentList(diffs: diffs, mode: mode, resetKey: commit.sha) { diff in
                CommitDiffFileHeader(diff: diff)
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            diffs = try await viewModel.loadDiff(for: commit.sha)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct CommitDiffFileHeader: View {
    let diff: DiffResult

    var body: some View {
        HStack(spacing: 12) {
            FileIconView(fileName: URL(fileURLWithPath: diff.filePath).lastPathComponent)

            VStack(alignment: .leading, spacing: 2) {
                Text(diff.filePath)
                    .font(.body.monospaced().bold())
                    .lineLimit(1)

                if let oldPath = diff.oldPath {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .imageScale(.small)
                        Text(oldPath)
                            .font(.caption.monospaced())
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if diff.additions > 0 {
                    Text("+\(diff.additions)")
                        .font(.caption.monospaced().bold())
                        .foregroundStyle(.green)
                }
                if diff.deletions > 0 {
                    Text("-\(diff.deletions)")
                        .font(.caption.monospaced().bold())
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.fill.quaternary)
    }
}
