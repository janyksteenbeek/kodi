import SwiftUI

struct ChangedFileRow: View {
    let file: ChangedFile
    @Bindable var viewModel: RepositoryViewModel
    var showDirectory: Bool = false

    var body: some View {
        Toggle(isOn: Binding(
            get: { file.isStaged },
            set: { _ in viewModel.toggleStaging(for: file) }
        )) {
            Label {
                Text(file.fileName)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } icon: {
                FileIconView(fileName: file.fileName)
            }
        }
        .toggleStyle(.checkbox)
        .badge(Text(file.status.rawValue).foregroundStyle(file.status.color))
    }
}
