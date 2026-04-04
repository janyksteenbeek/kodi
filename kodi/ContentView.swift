import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            DetailContentView(viewModel: viewModel)
                .inspector(isPresented: $viewModel.isInspectorVisible) {
                    InspectorView(viewModel: viewModel)
                        .inspectorColumnWidth(min: 250, ideal: 350, max: 500)
                }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

private struct DetailContentView: View {
    @Bindable var viewModel: RepositoryViewModel
    @AppStorage("primaryPanel") private var primaryPanel = "terminal"
    @State private var panelRatio: CGFloat = 0.5

    private var terminalIsPrimary: Bool { primaryPanel == "terminal" }

    var body: some View {
        if viewModel.isTerminalPanelVisible, viewModel.panelTerminal != nil {
            splitLayout
        } else {
            mainContent
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.editingFilePath != nil {
            CodeEditorView(viewModel: viewModel)
        } else if let terminal = viewModel.selectedTerminal,
           !(viewModel.isTerminalPanelVisible && viewModel.panelTerminalIDs.contains(terminal.id)) {
            TerminalTabView(session: terminal, viewModel: viewModel)
        } else {
            DiffContentView(viewModel: viewModel)
        }
    }

    private var splitLayout: some View {
        let isRight = viewModel.terminalPanelMode == .right

        return GeometryReader { geo in
            let layout = isRight
                ? AnyLayout(HStackLayout(spacing: 0))
                : AnyLayout(VStackLayout(spacing: 0))

            let total = isRight ? geo.size.width : geo.size.height
            let secondarySize = total * panelRatio

            layout {
                if terminalIsPrimary {
                    TerminalPanelView(viewModel: viewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    mainContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                SplitDivider(isHorizontal: isRight, panelRatio: $panelRatio, containerSize: total)

                if terminalIsPrimary {
                    mainContent
                        .frame(
                            width: isRight ? secondarySize : nil,
                            height: isRight ? nil : secondarySize
                        )
                } else {
                    TerminalPanelView(viewModel: viewModel)
                        .frame(
                            width: isRight ? secondarySize : nil,
                            height: isRight ? nil : secondarySize
                        )
                }
            }
        }
    }
}

private struct SplitDivider: View {
    let isHorizontal: Bool
    @Binding var panelRatio: CGFloat
    let containerSize: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(
                width: isHorizontal ? 1 : nil,
                height: isHorizontal ? nil : 1
            )
            .padding(isHorizontal ? .horizontal : .vertical, -4)
            .frame(
                width: isHorizontal ? 9 : nil,
                height: isHorizontal ? nil : 9
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    (isHorizontal ? NSCursor.resizeLeftRight : NSCursor.resizeUpDown).push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        let delta = isHorizontal ? -value.translation.width : -value.translation.height
                        let ratioDelta = delta / containerSize
                        panelRatio = min(max(panelRatio + ratioDelta, 0.15), 0.85)
                    }
            )
    }
}
