import SwiftUI

struct TerminalSessionRow: View {
    let session: TerminalSession
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        Label {
            Text(session.title)
                .lineLimit(1)
        } icon: {
            Image(systemName: "terminal")
                .foregroundStyle(session.isRunning ? .green : .secondary)
        }
        .onTapGesture(count: 2) {
            // Double click: open full screen
            viewModel.selectedFilePaths = [RepositoryViewModel.terminalTagPrefix + session.id.uuidString]
            viewModel.selectedFilePath = RepositoryViewModel.terminalTagPrefix + session.id.uuidString
        }
        .onTapGesture(count: 1) {
            // Single click: show in panel
            viewModel.showInPanel(session)
        }
        .contextMenu {
            Button {
                viewModel.selectedFilePaths = [RepositoryViewModel.terminalTagPrefix + session.id.uuidString]
                viewModel.selectedFilePath = RepositoryViewModel.terminalTagPrefix + session.id.uuidString
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
}
