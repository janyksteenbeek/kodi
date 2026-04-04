import SwiftUI

struct CodeEditorView: View {
    @Bindable var viewModel: RepositoryViewModel
    @AppStorage("diffFontSize") private var fontSize: Double = 12

    private var fileExtension: String {
        guard let path = viewModel.editingFilePath else { return "" }
        return URL(fileURLWithPath: path).pathExtension
    }

    private var fileName: String {
        guard let path = viewModel.editingFilePath else { return "" }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    var body: some View {
        VStack(spacing: 0) {
            // Editor header bar
            HStack(spacing: 8) {
                FileIconView(fileName: fileName)
                Text(fileName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                if viewModel.hasUnsavedChanges {
                    Circle()
                        .fill(.primary)
                        .frame(width: 6, height: 6)
                }

                Spacer()

                Button {
                    viewModel.saveCurrentFile()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.borderless)
                .disabled(!viewModel.hasUnsavedChanges)
                .help("Save")
                .keyboardShortcut("s", modifiers: .command)

                Button {
                    viewModel.closeEditor()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .help("Close Editor")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.fill.quaternary)

            Divider()

            CodeEditorNSViewRepresentable(
                text: $viewModel.editingFileContent,
                fileExtension: fileExtension,
                font: .monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular),
                onTextChange: {
                    viewModel.hasUnsavedChanges = true
                }
            )
        }
        .alert("Unsaved Changes", isPresented: $viewModel.showUnsavedAlert) {
            Button("Save") {
                viewModel.saveCurrentFile()
                if let pending = viewModel.pendingOpenFilePath {
                    viewModel.forceOpenFile(pending)
                }
            }
            Button("Discard", role: .destructive) {
                if let pending = viewModel.pendingOpenFilePath {
                    viewModel.forceOpenFile(pending)
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.pendingOpenFilePath = nil
            }
        } message: {
            Text("Do you want to save changes before opening another file?")
        }
    }
}
