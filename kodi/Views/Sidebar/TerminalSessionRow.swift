import SwiftUI

struct TerminalSessionRow: View {
    let session: TerminalSession
    @Bindable var viewModel: RepositoryViewModel
    @AppStorage("terminalClickAction") private var terminalClickAction = "panel"

    private var tag: String {
        RepositoryViewModel.terminalTagPrefix + session.id.uuidString
    }

    var body: some View {
        Label {
            Text(session.title)
                .lineLimit(1)
        } icon: {
            Image(systemName: "terminal")
                .foregroundStyle(session.isRunning ? .green : .secondary)
        }
        .tag(tag)
        .contextMenu {
            Button {
                openFullScreen()
            } label: {
                Label("Open Full Screen", systemImage: "macwindow")
            }
            Button {
                viewModel.showInPanel(session)
            } label: {
                Label("Show in Panel", systemImage: "rectangle.split.1x2")
            }
            Divider()
            Button(role: .destructive) {
                viewModel.closeTerminal(session)
            } label: {
                Label("Close Terminal", systemImage: "xmark.circle")
            }
        }
    }

    private func openFullScreen() {
        viewModel.selectedFilePaths = [tag]
        viewModel.selectedFilePath = tag
    }
}
