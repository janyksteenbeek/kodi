import SwiftUI

struct DiffHeaderView: View {
    let diff: DiffResult
    @Bindable var viewModel: RepositoryViewModel

    private var changedFile: ChangedFile? {
        viewModel.changedFiles.first { $0.path == diff.filePath }
    }

    var body: some View {
        HStack(spacing: 12) {
            if let file = changedFile {
                Toggle(isOn: Binding(
                    get: { file.isStaged },
                    set: { _ in viewModel.toggleStaging(for: file) }
                )) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .labelsHidden()
            }

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
