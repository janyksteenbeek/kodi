import SwiftUI

struct ChangedFileRow: View {
    let file: ChangedFile
    @Bindable var viewModel: RepositoryViewModel
    var showDirectory: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Toggle(isOn: Binding(
                get: { file.isStaged },
                set: { _ in viewModel.toggleStaging(for: file) }
            )) {
                EmptyView()
            }
            .toggleStyle(.checkbox)
            .labelsHidden()

            FileIconView(fileName: file.fileName)

            Text(file.fileName)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(file.status.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(file.status.color)
        }
        .tag(file.path)
    }
}
