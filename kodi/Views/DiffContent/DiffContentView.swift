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
                } else {
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
                DiffContentList(
                    diffs: viewModel.currentDiff,
                    mode: viewModel.diffMode,
                    resetKey: viewModel.selectedFilePath ?? ""
                ) { diff in
                    DiffHeaderView(diff: diff, viewModel: viewModel)
                }
            }
        }
    }
}

struct DiffContentList<Header: View>: View {
    let diffs: [DiffResult]
    let mode: RepositoryViewModel.DiffMode
    let resetKey: String
    @ViewBuilder let header: (DiffResult) -> Header

    private let largeDiffThreshold = 500
    @State private var expandedLargeDiffs: Set<String> = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(diffs) { diffResult in
                    let isLarge = diffResult.totalLines > largeDiffThreshold
                    let isExpanded = expandedLargeDiffs.contains(diffResult.id)

                    VStack(alignment: .leading, spacing: 0) {
                        header(diffResult)

                        if isLarge && !isExpanded {
                            VStack(spacing: 8) {
                                Text("Large diff hidden — \(diffResult.totalLines) lines")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Button("Show Diff") {
                                    expandedLargeDiffs.insert(diffResult.id)
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            switch mode {
                            case .unified:
                                UnifiedDiffView(diff: diffResult)
                            case .sideBySide:
                                SideBySideDiffView(diff: diffResult)
                            }
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
        .onChange(of: resetKey) {
            expandedLargeDiffs.removeAll()
        }
    }
}
