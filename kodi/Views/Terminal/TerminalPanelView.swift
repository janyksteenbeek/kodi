import SwiftUI

struct TerminalPanelView: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            Divider()

            if let session = viewModel.panelTerminal {
                TerminalNSViewRepresentable(session: session)
            } else {
                ContentUnavailableView {
                    Label("No Terminal", systemImage: "terminal")
                } actions: {
                    Button("New Terminal") {
                        viewModel.createTerminalInPanel()
                    }
                }
            }
        }
    }

    private var panelHeader: some View {
        HStack(spacing: 6) {
            if viewModel.terminalSessions.count > 1 {
                Picker(selection: panelTerminalBinding, content: {
                    ForEach(viewModel.terminalSessions) { session in
                        Text(session.title).tag(session.id)
                    }
                }, label: {
                    EmptyView()
                })
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 150)
            } else if let session = viewModel.panelTerminal {
                Label(session.title, systemImage: "terminal")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                viewModel.createTerminalInPanel()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("New Terminal")

            Button {
                viewModel.terminalPanelMode = viewModel.terminalPanelMode == .bottom ? .right : .bottom
            } label: {
                Image(systemName: viewModel.terminalPanelMode == .bottom
                      ? "rectangle.split.2x1"
                      : "rectangle.split.1x2")
            }
            .buttonStyle(.borderless)
            .help(viewModel.terminalPanelMode == .bottom ? "Split Right" : "Split Bottom")

            Button {
                viewModel.isTerminalPanelVisible = false
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Hide Terminal Panel")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var panelTerminalBinding: Binding<UUID> {
        Binding(
            get: { viewModel.panelTerminalID ?? viewModel.terminalSessions.first?.id ?? UUID() },
            set: { viewModel.panelTerminalID = $0 }
        )
    }
}
