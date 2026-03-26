import SwiftUI

struct TerminalTabView: View {
    let session: TerminalSession
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        TerminalNSViewRepresentable(session: session)
            .navigationTitle(session.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showInPanel(session)
                        viewModel.selectedFilePath = nil
                    } label: {
                        Label("Move to Panel", systemImage: "rectangle.split.1x2")
                    }
                    .help("Move to panel")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.closeTerminal(session)
                    } label: {
                        Label("Close Terminal", systemImage: "xmark")
                    }
                    .help("Close terminal")
                }
            }
    }
}
