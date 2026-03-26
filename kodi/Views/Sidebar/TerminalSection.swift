import SwiftUI

struct TerminalSection: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        Section {
            ForEach(viewModel.terminalSessions) { session in
                TerminalSessionRow(session: session, viewModel: viewModel)
                    .tag(RepositoryViewModel.terminalTagPrefix + session.id.uuidString)
            }

            Button {
                viewModel.createTerminal()
            } label: {
                Label("Open Terminal", systemImage: "plus")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        } header: {
            Text("Terminals")
        }
    }
}
