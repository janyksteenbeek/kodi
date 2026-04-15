import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            DetailContentView(viewModel: viewModel)
                .inspector(isPresented: $viewModel.isInspectorVisible) {
                    InspectorView(viewModel: viewModel)
                        .inspectorColumnWidth(min: 250, ideal: 350, max: 500)
                }
        }
        .frame(minWidth: 800, minHeight: 500)
        .overlay {
            if viewModel.isGlobalSearchVisible {
                ZStack {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.isGlobalSearchVisible = false
                        }

                    VStack {
                        GlobalSearchView(viewModel: viewModel)
                            .padding(.top, 80)
                        Spacer()
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: viewModel.isGlobalSearchVisible)
    }
}

private struct DetailContentView: View {
    @Bindable var viewModel: RepositoryViewModel
    @AppStorage("primaryPanel") private var primaryPanel = "terminal"
    @State private var panelRatio: CGFloat = 0.5
    @State private var splitContainerLength: CGFloat = 0

    private var terminalIsPrimary: Bool { primaryPanel == "terminal" }

    var body: some View {
        Group {
            if viewModel.isTerminalPanelVisible, viewModel.panelTerminal != nil {
                splitLayout
            } else {
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                BranchPickerView(viewModel: viewModel)
            }

            ToolbarItemGroup(placement: .automatic) {
                Picker("Diff Mode", selection: $viewModel.diffMode) {
                    ForEach(RepositoryViewModel.DiffMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    viewModel.toggleTerminalPanel()
                } label: {
                    Label("Terminal", systemImage: viewModel.isTerminalPanelVisible ? "terminal.fill" : "terminal")
                }
                .help(viewModel.isTerminalPanelVisible ? "Hide Terminal" : "Show Terminal")

                if viewModel.isTerminalPanelVisible {
                    Button {
                        viewModel.terminalPanelMode = viewModel.terminalPanelMode == .bottom ? .right : .bottom
                    } label: {
                        Label(
                            viewModel.terminalPanelMode == .bottom ? "Split Right" : "Split Bottom",
                            systemImage: viewModel.terminalPanelMode == .bottom
                                ? "rectangle.righthalf.inset.filled"
                                : "rectangle.bottomhalf.inset.filled"
                        )
                    }
                    .help(viewModel.terminalPanelMode == .bottom ? "Split Right" : "Split Bottom")
                }

                Button {
                    viewModel.isInspectorVisible.toggle()
                } label: {
                    Label("Files", systemImage: "sidebar.trailing")
                }
                .help(viewModel.isInspectorVisible ? "Hide Files" : "Show Files")
            }
        }
        .navigationSubtitle(navigationSubtitle)
    }

    private var navigationSubtitle: String {
        if viewModel.isEditorVisible, let session = viewModel.editorSessions.last {
            return session.relativePath
        }
        if let sel = viewModel.selectedFilePath,
           sel.hasPrefix(RepositoryViewModel.folderTagPrefix) {
            return String(sel.dropFirst(RepositoryViewModel.folderTagPrefix.count))
        }
        if let file = viewModel.selectedFile {
            return file.directory.isEmpty ? file.fileName : "\(file.directory)/\(file.fileName)"
        }
        return "\(viewModel.currentDiff.count) changed file\(viewModel.currentDiff.count == 1 ? "" : "s")"
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isEditorVisible {
            EditorPanelView(viewModel: viewModel)
        } else if let terminal = viewModel.selectedTerminal,
           !(viewModel.isTerminalPanelVisible && viewModel.panelTerminalIDs.contains(terminal.id)) {
            TerminalTabView(session: terminal, viewModel: viewModel)
        } else {
            DiffContentView(viewModel: viewModel)
        }
    }

    private var splitLayout: some View {
        let isRight = viewModel.terminalPanelMode == .right

        return SplitPanelLayout(isHorizontal: isRight, secondaryRatio: panelRatio) {
            if terminalIsPrimary {
                TerminalPanelView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            SplitDivider(isHorizontal: isRight, panelRatio: $panelRatio, containerSize: splitContainerLength)

            if terminalIsPrimary {
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TerminalPanelView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            isRight ? proxy.size.width : proxy.size.height
        } action: { newValue in
            splitContainerLength = newValue
        }
    }
}

private struct SplitDivider: View {
    let isHorizontal: Bool
    @Binding var panelRatio: CGFloat
    let containerSize: CGFloat

    @GestureState private var dragStartRatio: CGFloat? = nil

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
                    .updating($dragStartRatio) { _, state, _ in
                        if state == nil { state = panelRatio }
                    }
                    .onChanged { value in
                        guard containerSize > 0 else { return }
                        let startRatio = dragStartRatio ?? panelRatio
                        let delta = isHorizontal ? -value.translation.width : -value.translation.height
                        panelRatio = min(max(startRatio + delta / containerSize, 0.15), 0.85)
                    }
            )
    }
}

private struct SplitPanelLayout: Layout {
    let isHorizontal: Bool
    let secondaryRatio: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        guard subviews.count == 3 else { return }

        let dividerThickness: CGFloat = 9
        let total = isHorizontal ? bounds.width : bounds.height
        let available = max(total - dividerThickness, 0)
        let secondarySize = available * secondaryRatio
        let primarySize = available - secondarySize

        if isHorizontal {
            subviews[0].place(at: bounds.origin, proposal: .init(width: primarySize, height: bounds.height))
            subviews[1].place(at: .init(x: bounds.minX + primarySize, y: bounds.minY), proposal: .init(width: dividerThickness, height: bounds.height))
            subviews[2].place(at: .init(x: bounds.minX + primarySize + dividerThickness, y: bounds.minY), proposal: .init(width: secondarySize, height: bounds.height))
        } else {
            subviews[0].place(at: bounds.origin, proposal: .init(width: bounds.width, height: primarySize))
            subviews[1].place(at: .init(x: bounds.minX, y: bounds.minY + primarySize), proposal: .init(width: bounds.width, height: dividerThickness))
            subviews[2].place(at: .init(x: bounds.minX, y: bounds.minY + primarySize + dividerThickness), proposal: .init(width: bounds.width, height: secondarySize))
        }
    }
}
