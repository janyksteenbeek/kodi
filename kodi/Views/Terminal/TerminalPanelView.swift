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
            if let session = viewModel.panelTerminal {
                PanelTerminalLabel(session: session)
            }

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
                .frame(maxWidth: 120)
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

private struct PanelTerminalLabel: View {
    let session: TerminalSession

    var body: some View {
        HStack(spacing: 4) {
            if session.program.isCustomImage {
                Image(session.program.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundStyle(session.program.color)
            } else {
                Image(systemName: session.program.icon)
                    .font(.caption)
                    .foregroundStyle(session.program.color)
            }

            switch session.activityState {
            case .loading:
                ProgressView()
                    .controlSize(.mini)
                Text("Loading…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .busy:
                Circle()
                    .fill(session.program.color)
                    .frame(width: 5, height: 5)
                    .opacity(0.8)
            case .idle:
                EmptyView()
            }
        }
    }
}
