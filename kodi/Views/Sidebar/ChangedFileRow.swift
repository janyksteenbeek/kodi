import SwiftUI

struct ChangedFileRow: View {
    let file: ChangedFile
    @Bindable var viewModel: RepositoryViewModel
    var showDirectory: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Toggle("", isOn: Binding(
                get: { file.isStaged },
                set: { _ in viewModel.toggleStaging(for: file) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            FileIconView(fileName: file.fileName)

            VStack(alignment: .leading, spacing: 1) {
                Text(file.fileName)
                    .lineLimit(1)

                if showDirectory, !file.directory.isEmpty {
                    Text(file.directory)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(file.directory)
                }
            }

            Spacer()

            StatusBadge(status: file.status)
        }
    }
}
