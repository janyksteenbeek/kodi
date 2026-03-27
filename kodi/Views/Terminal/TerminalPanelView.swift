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

            if viewModel.panelTerminals.count > 1 {
                Menu {
                    Picker("Layout", selection: $viewModel.terminalPaneLayout) {
                        ForEach(RepositoryViewModel.TerminalPaneLayout.allCases, id: \.self) { layout in
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
        switch viewModel.terminalPaneLayout {
        case .horizontal:
            linearLayout(isHorizontal: true)
        case .vertical:
            linearLayout(isHorizontal: false)
        case .grid:
            gridLayout()
        }
    }

    @ViewBuilder
    private func linearLayout(isHorizontal: Bool) -> some View {
        let layout = isHorizontal
            ? AnyLayout(HStackLayout(spacing: 0))
            : AnyLayout(VStackLayout(spacing: 0))

        layout {
            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                if index > 0 {
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(width: isHorizontal ? 1 : nil, height: isHorizontal ? nil : 1)
                }
                paneView(session: session)
            }
        }
    }

    @ViewBuilder
    private func gridLayout() -> some View {
        let (rows, cols) = gridDimensions(count: sessions.count)

        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                if row > 0 {
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 1)
                }
                HStack(spacing: 0) {
                    ForEach(0..<cols, id: \.self) { col in
                        let index = row * cols + col
                        if col > 0 {
                            Rectangle()
                                .fill(Color(nsColor: .separatorColor))
                                .frame(width: 1)
                        }
                        if index < sessions.count {
                            paneView(session: sessions[index])
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    private func gridDimensions(count: Int) -> (rows: Int, cols: Int) {
        switch count {
        case 1: return (1, 1)
        case 2: return (1, 2)
        case 3, 4: return (2, 2)
        case 5, 6: return (2, 3)
        case 7, 8: return (2, 4)
        default:
            let cols = Int(ceil(sqrt(Double(count))))
            let rows = Int(ceil(Double(count) / Double(cols)))
            return (rows, cols)
        }
    }

    @ViewBuilder
    private func paneView(session: TerminalSession) -> some View {
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
