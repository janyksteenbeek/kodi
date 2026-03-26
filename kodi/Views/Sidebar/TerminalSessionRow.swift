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
        .contextMenu {
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
