import SwiftUI

struct ChangedFileRow: View {
    let file: ChangedFile
    @Bindable var viewModel: RepositoryViewModel
    var showDirectory: Bool = false

    @AppStorage("showFileIcons") private var showFileIcons = true

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

            if showFileIcons {
                FileIconView(fileName: file.fileName)
            }

            Text(file.fileName)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(file.status.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(file.status.color)
        }
        .padding(.vertical, 3)
        .tag(file.path)
    }
}
