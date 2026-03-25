import SwiftUI

struct ChangedFileRow: View {
    let file: ChangedFile
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: Binding(
                get: { file.isStaged },
                set: { _ in viewModel.toggleStaging(for: file) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            FileIconView(fileName: file.fileName)

            VStack(alignment: .leading, spacing: 1) {
                Text(file.fileName)
                    .font(.body)
                    .lineLimit(1)
                if !file.directory.isEmpty {
                    Text(file.directory)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            StatusBadge(status: file.status)
        }
        .contentShape(Rectangle())
    }
}
