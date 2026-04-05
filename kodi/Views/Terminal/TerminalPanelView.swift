import SwiftUI

struct TerminalPanelView: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            Divider()

            let terminals = viewModel.panelTerminals
            if terminals.isEmpty {
                ContentUnavailableView {
                    Label("No Terminal", systemImage: "terminal")
                } actions: {
                    Button("New Terminal") {
                        viewModel.createTerminalInPanel()
                    }
                }
            } else {
                MultiPaneView(
                    items: terminals,
                    layout: viewModel.terminalPaneLayout,
                    header: { session in
                        PanelTerminalLabel(session: session)
                        Text(session.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    },
                    content: { session in
                        TerminalNSViewRepresentable(session: session)
                    },
                    onClose: { session in
                        viewModel.panelTerminalIDs.removeAll { $0 == session.id }
                        if viewModel.panelTerminalIDs.isEmpty {
                            if let first = viewModel.terminalSessions.first {
                                viewModel.panelTerminalIDs = [first.id]
                            } else {
                                viewModel.isTerminalPanelVisible = false
                            }
                        }
                    }
                )
            }
        }
    }

    private var panelHeader: some View {
        HStack(spacing: 6) {
            let terminals = viewModel.panelTerminals
            if terminals.count == 1, let session = terminals.first {
                PanelTerminalLabel(session: session)
            } else if terminals.count > 1 {
                ForEach(terminals) { session in
                    PanelTerminalLabel(session: session)
                }
            }

            if viewModel.terminalSessions.count > 1 && viewModel.panelTerminals.count <= 1 {
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

            if viewModel.panelTerminals.count == 2 {
                Button {
                    viewModel.terminalPaneLayout = viewModel.terminalPaneLayout == .horizontal ? .vertical : .horizontal
                } label: {
                    Image(systemName: viewModel.terminalPaneLayout == .horizontal
                        ? PaneLayout.vertical.icon
                        : PaneLayout.horizontal.icon)
                }
                .buttonStyle(.borderless)
                .help(viewModel.terminalPaneLayout == .horizontal ? "Stack Vertically" : "Side by Side")
            } else if viewModel.panelTerminals.count > 2 {
                Menu {
                    Picker("Layout", selection: $viewModel.terminalPaneLayout) {
                        ForEach(PaneLayout.allCases, id: \.self) { layout in
                            Label(layout.rawValue, systemImage: layout.icon)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.terminalPaneLayout.icon)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Pane Layout")
            }

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
