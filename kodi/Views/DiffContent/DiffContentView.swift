import SwiftUI

struct DiffContentView: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        Group {
            if viewModel.currentDiff.isEmpty {
                if viewModel.selectedFilePath != nil && viewModel.isLoading {
                    ProgressView("Loading diff…")
                } else {
                    ContentUnavailableView(
                        "Select a File",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Choose a changed file from the sidebar to view its diff")
                    )
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
            }
        }
        .navigationTitle(navigationTitle)
        .navigationSubtitle(navigationSubtitle)
    }

    private var isMultiFile: Bool {
        guard let sel = viewModel.selectedFilePath else { return false }
        return sel == RepositoryViewModel.allChangesTag || sel.hasPrefix(RepositoryViewModel.folderTagPrefix)
    }

    private var navigationTitle: String {
        if let sel = viewModel.selectedFilePath {
            if sel == RepositoryViewModel.allChangesTag {
                return "All Changes"
            }
            if sel.hasPrefix(RepositoryViewModel.folderTagPrefix) {
                return String(sel.dropFirst(RepositoryViewModel.folderTagPrefix.count))
            }
        }
        return viewModel.selectedFile?.fileName ?? viewModel.repository.displayName
    }

    private var navigationSubtitle: String {
        if isMultiFile {
            return "\(viewModel.currentDiff.count) file\(viewModel.currentDiff.count == 1 ? "" : "s")"
        }
        return viewModel.selectedFile?.directory ?? ""
    }
}
