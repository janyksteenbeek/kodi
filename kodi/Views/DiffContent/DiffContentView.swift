import SwiftUI

struct DiffContentView: View {
    @Bindable var viewModel: RepositoryViewModel
    private let largeDiffThreshold = 500
    @State private var expandedLargeDiffs: Set<UUID> = []

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
                            let isLarge = diffResult.totalLines > largeDiffThreshold
                            let isExpanded = expandedLargeDiffs.contains(diffResult.id)

                            VStack(alignment: .leading, spacing: 0) {
                                DiffHeaderView(diff: diffResult, viewModel: viewModel)

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
                                    switch viewModel.diffMode {
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
            }
        }
        .onChange(of: viewModel.selectedFilePath) {
            expandedLargeDiffs.removeAll()
        }
    }
}
