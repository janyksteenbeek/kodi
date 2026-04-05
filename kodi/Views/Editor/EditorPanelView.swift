import SwiftUI

struct EditorPanelView: View {
    @Bindable var viewModel: RepositoryViewModel
    @AppStorage("diffFontSize") private var fontSize: Double = 12

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            Divider()

            if viewModel.editorSessions.isEmpty {
                ContentUnavailableView {
                    Label("No Open Files", systemImage: "doc")
                } description: {
                    Text("Open a file from the directory tree")
                }
            } else if viewModel.editorSessions.count == 1 {
                singleEditorView(viewModel.editorSessions[0])
            } else {
                MultiPaneView(
                    items: viewModel.editorSessions,
                    layout: viewModel.editorPaneLayout,
                    header: { session in
                        FileIconView(fileName: session.fileName)
                        Text(session.fileName)
                            .font(.caption)
                            .lineLimit(1)
                        if session.hasUnsavedChanges {
                            Circle().fill(.primary).frame(width: 5, height: 5)
                        }
                    },
                    content: { session in
                        if session.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            EditorNSViewRepresentable(session: session)
                        }
                    },
                    onClose: { session in
                        if session.hasUnsavedChanges {
                            viewModel.pendingCloseSession = session
                            viewModel.showUnsavedAlert = true
                        } else {
                            viewModel.closeEditor(session)
                        }
                    }
                )
            }
        }
        .onChange(of: fontSize) {
            let font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
            for session in viewModel.editorSessions {
                session.updateFont(font)
            }
        }
        .alert("Unsaved Changes", isPresented: $viewModel.showUnsavedAlert) {
            Button("Save") {
                if let session = viewModel.pendingCloseSession {
                    viewModel.saveEditor(session)
                    viewModel.closeEditor(session)
                }
            }
            Button("Discard", role: .destructive) {
                if let session = viewModel.pendingCloseSession {
                    viewModel.closeEditor(session)
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.pendingCloseSession = nil
            }
        } message: {
            Text("Do you want to save changes before closing?")
        }
    }

    // MARK: - Single editor (no multi-pane chrome)

    @ViewBuilder
    private func singleEditorView(_ session: EditorSession) -> some View {
        if session.isLoading {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            EditorNSViewRepresentable(session: session)
        }
    }

    // MARK: - Header

    private var editorHeader: some View {
        HStack(spacing: 6) {
            // Single file: show file name in header
            if viewModel.editorSessions.count == 1, let session = viewModel.editorSessions.first {
                FileIconView(fileName: session.fileName)
                Text(session.fileName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                if session.hasUnsavedChanges {
                    Circle().fill(.primary).frame(width: 6, height: 6)
                }
            }

            Spacer()

            if viewModel.editorSessions.count == 2 {
                Button {
                    viewModel.editorPaneLayout = viewModel.editorPaneLayout == .horizontal ? .vertical : .horizontal
                } label: {
                    Image(systemName: viewModel.editorPaneLayout == .horizontal
                        ? PaneLayout.vertical.icon
                        : PaneLayout.horizontal.icon)
                }
                .buttonStyle(.borderless)
                .help(viewModel.editorPaneLayout == .horizontal ? "Stack Vertically" : "Side by Side")
            } else if viewModel.editorSessions.count > 2 {
                Menu {
                    Picker("Layout", selection: $viewModel.editorPaneLayout) {
                        ForEach(PaneLayout.allCases, id: \.self) { layout in
                            Label(layout.rawValue, systemImage: layout.icon)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.editorPaneLayout.icon)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Pane Layout")
            }

            if viewModel.hasAnyUnsavedChanges {
                Button {
                    for session in viewModel.editorSessions {
                        if session.hasUnsavedChanges { session.save() }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.borderless)
                .help("Save All")
            }

            Button {
                viewModel.closeAllEditors()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Close All")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// MARK: - Editor NSView Representable

struct EditorNSViewRepresentable: NSViewRepresentable {
    let session: EditorSession

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        attachEditorView(to: container)
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let sv = session.scrollView else { return }
        if sv.superview == nsView { return }

        for subview in nsView.subviews {
            subview.removeFromSuperview()
        }
        attachEditorView(to: nsView)
    }

    private func attachEditorView(to container: NSView) {
        guard let sv = session.scrollView else { return }

        sv.removeFromSuperview()
        sv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(sv)
        NSLayoutConstraint.activate([
            sv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            sv.topAnchor.constraint(equalTo: container.topAnchor),
            sv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        sv.needsLayout = true
        sv.needsDisplay = true
    }
}
