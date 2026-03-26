import SwiftUI

struct DiffContentView: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        Group {
            if viewModel.currentDiff.isEmpty {
                if viewModel.isLoading {
                    ProgressView("Loading…")
                } else if !viewModel.changedFiles.isEmpty {
                    ContentUnavailableView(
                        "Select a File",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Choose a changed file from the sidebar to view its diff")
                    )
                } else if !viewModel.isTerminalPanelVisible {
                    VStack {
                        Spacer()
                        QuickLaunchGrid { item in
                            viewModel.launchQuickItem(item)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.currentDiff) { diffResult in
                            VStack(alignment: .leading, spacing: 0) {
                                DiffHeaderView(diff: diffResult)

                                switch viewModel.diffMode {
                                case .unified:
                                    UnifiedDiffView(diff: diffResult)
                                case .sideBySide:
                                    SideBySideDiffView(diff: diffResult)
                                }
                            }
                            .clipShape(.rect(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.quaternary, lineWidth: 1)
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .toolbar {
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
                    Label("Terminal", systemImage: "terminal")
                }
                .help(viewModel.isTerminalPanelVisible ? "Hide Terminal" : "Show Terminal")
            }
        }
        .navigationTitle(navigationTitle)
        .navigationSubtitle(navigationSubtitle)
    }

    private var navigationTitle: String {
        if let sel = viewModel.selectedFilePath,
           sel.hasPrefix(RepositoryViewModel.folderTagPrefix) {
            return String(sel.dropFirst(RepositoryViewModel.folderTagPrefix.count))
        }
        return viewModel.selectedFile?.fileName ?? viewModel.repository.displayName
    }

    private var navigationSubtitle: String {
        if viewModel.selectedFilePath == nil {
            return "\(viewModel.currentDiff.count) changed file\(viewModel.currentDiff.count == 1 ? "" : "s")"
        }
        if let sel = viewModel.selectedFilePath,
           sel.hasPrefix(RepositoryViewModel.folderTagPrefix) {
            return ""
        }
        return viewModel.selectedFile?.directory ?? ""
    }
}
