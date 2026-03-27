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
                TerminalMultiPaneView(sessions: terminals, viewModel: viewModel)
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

// MARK: - Multi-pane terminal view

private struct TerminalMultiPaneView: View {
    let sessions: [TerminalSession]
    @Bindable var viewModel: RepositoryViewModel

    private var showPaneHeaders: Bool { sessions.count > 1 }

    var body: some View {
        GeometryReader { geo in
            let paneWidth = geo.size.width / CGFloat(sessions.count)

            HStack(spacing: 0) {
                ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                    if index > 0 {
                        Rectangle()
                            .fill(Color(nsColor: .separatorColor))
                            .frame(width: 1)
                    }

                    VStack(spacing: 0) {
                        if showPaneHeaders {
                            HStack(spacing: 4) {
                                PanelTerminalLabel(session: session)
                                Text(session.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Button {
                                    viewModel.panelTerminalIDs.removeAll { $0 == session.id }
                                    if viewModel.panelTerminalIDs.isEmpty {
                                        if let first = viewModel.terminalSessions.first {
                                            viewModel.panelTerminalIDs = [first.id]
                                        } else {
                                            viewModel.isTerminalPanelVisible = false
                                        }
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                                .buttonStyle(.borderless)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(nsColor: .controlBackgroundColor))

                            Divider()
                        }

                        TerminalNSViewRepresentable(session: session)
                    }
                    .frame(width: paneWidth - (index > 0 ? 0.5 : 0) - (index < sessions.count - 1 ? 0.5 : 0))
                }
            }
        }
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
