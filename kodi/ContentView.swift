import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            DetailContentView(viewModel: viewModel)
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

private struct DetailContentView: View {
    @Bindable var viewModel: RepositoryViewModel
    @AppStorage("primaryPanel") private var primaryPanel = "terminal"
    @State private var panelSize: CGFloat = 250

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
        if let terminal = viewModel.selectedTerminal,
           !(viewModel.isTerminalPanelVisible && viewModel.panelTerminalID == terminal.id) {
            TerminalTabView(session: terminal, viewModel: viewModel)
        } else {
            DiffContentView(viewModel: viewModel)
        }
    }

    private var splitLayout: some View {
        let isRight = viewModel.terminalPanelMode == .right
        let layout = isRight
            ? AnyLayout(HStackLayout(spacing: 0))
            : AnyLayout(VStackLayout(spacing: 0))

        let primaryView = terminalIsPrimary
            ? AnyView(TerminalPanelView(viewModel: viewModel))
            : AnyView(mainContent)

        let secondaryView = terminalIsPrimary
            ? AnyView(mainContent)
            : AnyView(TerminalPanelView(viewModel: viewModel))

        return layout {
            primaryView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

            SplitDivider(isHorizontal: isRight, panelSize: $panelSize)

            secondaryView
                .frame(
                    width: isRight ? panelSize : nil,
                    height: isRight ? nil : panelSize
                )
        }
    }
}

private struct SplitDivider: View {
    let isHorizontal: Bool
    @Binding var panelSize: CGFloat

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
                        panelSize = min(max(panelSize + delta, 120), 600)
                    }
            )
    }
}
