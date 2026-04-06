import SwiftUI
import CodeEditSourceEditor
import CodeEditLanguages

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
                            SourceEditorView(session: session, fontSize: fontSize)
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
            SourceEditorView(session: session, fontSize: fontSize)
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

// MARK: - Source Editor Wrapper

private struct SourceEditorView: View {
    @Bindable var session: EditorSession
    let fontSize: Double

    @Environment(\.colorScheme) private var colorScheme

    @State private var editorState = SourceEditorState()
    @State private var lastSavedContent: String = ""

    private var theme: EditorTheme {
        colorScheme == .dark ? .defaultDark : .defaultLight
    }

    private var font: NSFont {
        .monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
    }

    var body: some View {
        SourceEditor(
            $session.content,
            language: session.language,
            configuration: SourceEditorConfiguration(
                appearance: .init(
                    theme: theme,
                    font: font,
                    wrapLines: true
                ),
                peripherals: .init(showMinimap: false)
            ),
            state: $editorState
        )
        .onAppear {
            lastSavedContent = session.content
        }
        .onChange(of: session.content) {
            session.hasUnsavedChanges = session.content != lastSavedContent
        }
        .onChange(of: session.hasUnsavedChanges) {
            if !session.hasUnsavedChanges {
                lastSavedContent = session.content
            }
        }
    }
}

// MARK: - Default Themes

extension EditorTheme {
    static var defaultLight: EditorTheme {
        EditorTheme(
            text: Attribute(color: .labelColor),
            insertionPoint: .labelColor,
            invisibles: Attribute(color: .tertiaryLabelColor),
            background: NSColor.textBackgroundColor.usingColorSpace(.sRGB) ?? .white,
            lineHighlight: (NSColor.selectedContentBackgroundColor.usingColorSpace(.sRGB) ?? .gray).withAlphaComponent(0.1),
            selection: NSColor.selectedTextBackgroundColor.usingColorSpace(.sRGB) ?? .selectedTextBackgroundColor,
            keywords: Attribute(color: .systemPink, bold: true),
            commands: Attribute(color: .systemTeal),
            types: Attribute(color: .systemBlue),
            attributes: Attribute(color: .systemPurple),
            variables: Attribute(color: .systemCyan),
            values: Attribute(color: .systemIndigo),
            numbers: Attribute(color: .systemBlue),
            strings: Attribute(color: .systemRed),
            characters: Attribute(color: .systemOrange),
            comments: Attribute(color: .secondaryLabelColor)
        )
    }

    static var defaultDark: EditorTheme {
        EditorTheme(
            text: Attribute(color: .labelColor),
            insertionPoint: .labelColor,
            invisibles: Attribute(color: .tertiaryLabelColor),
            background: NSColor.textBackgroundColor.usingColorSpace(.sRGB) ?? .black,
            lineHighlight: (NSColor.selectedContentBackgroundColor.usingColorSpace(.sRGB) ?? .gray).withAlphaComponent(0.1),
            selection: NSColor.selectedTextBackgroundColor.usingColorSpace(.sRGB) ?? .selectedTextBackgroundColor,
            keywords: Attribute(color: .systemPink, bold: true),
            commands: Attribute(color: .systemTeal),
            types: Attribute(color: .systemCyan),
            attributes: Attribute(color: .systemOrange),
            variables: Attribute(color: .systemBlue),
            values: Attribute(color: .systemPurple),
            numbers: Attribute(color: .systemYellow),
            strings: Attribute(color: .systemRed),
            characters: Attribute(color: .systemOrange),
            comments: Attribute(color: .secondaryLabelColor)
        )
    }
}
