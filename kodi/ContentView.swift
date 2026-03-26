import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            if let vm = appState.selectedViewModel {
                DetailContentView(viewModel: vm)
            } else {
                ContentUnavailableView(
                    "Welcome to Kodi",
                    systemImage: "arrow.triangle.branch",
                    description: Text("Add a git repository to start viewing diffs")
                )
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .task {
            appState.loadSavedRepositories()
        }
    }
}

private struct DetailContentView: View {
    @Bindable var viewModel: RepositoryViewModel
    @State private var panelSize: CGFloat = 250

    var body: some View {
        if viewModel.isTerminalPanelVisible, viewModel.panelTerminal != nil {
            GeometryReader { geo in
                splitLayout(in: geo.size)
            }
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

    @ViewBuilder
    private func splitLayout(in size: CGSize) -> some View {
        let isRight = viewModel.terminalPanelMode == .right

        if isRight {
            HStack(spacing: 0) {
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                SplitDivider(isHorizontal: true, panelSize: $panelSize, containerSize: size.width)
                TerminalPanelView(viewModel: viewModel)
                    .frame(width: panelSize, alignment: .leading)
            }
        } else {
            VStack(spacing: 0) {
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                SplitDivider(isHorizontal: false, panelSize: $panelSize, containerSize: size.height)
                TerminalPanelView(viewModel: viewModel)
                    .frame(height: panelSize, alignment: .top)
            }
        }
    }
}

private struct SplitDivider: View {
    let isHorizontal: Bool
    @Binding var panelSize: CGFloat
    let containerSize: CGFloat

    var body: some View {
        ZStack {
            if isHorizontal {
                Color.clear
                    .frame(width: 9)
                    .contentShape(Rectangle())
                    .overlay(
                        Rectangle()
                            .fill(Color(nsColor: .separatorColor))
                            .frame(width: 1)
                    )
            } else {
                Color.clear
                    .frame(height: 9)
                    .contentShape(Rectangle())
                    .overlay(
                        Rectangle()
                            .fill(Color(nsColor: .separatorColor))
                            .frame(height: 1)
                    )
            }
        }
        .onHover { hovering in
            if hovering {
                if isHorizontal {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.resizeUpDown.push()
                }
            } else {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    let delta = isHorizontal ? -value.translation.width : -value.translation.height
                    let newSize = panelSize + delta
                    let minSize: CGFloat = 120
                    let maxSize = containerSize * 0.75
                    panelSize = min(max(newSize, minSize), maxSize)
                }
        )
    }
}
