import SwiftUI

struct RepositorySection: View {
    let repository: GitRepository
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        Section {
            if viewModel.changedFiles.isEmpty {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    Text("No changes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            } else {
                ForEach(viewModel.changedFiles) { file in
                    ChangedFileRow(file: file, viewModel: viewModel)
                        .tag(file.path)
                }
            }
        } header: {
            HStack {
                Label(repository.displayName, systemImage: "arrow.triangle.branch")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if !viewModel.changedFiles.isEmpty {
                    Text("\(viewModel.changedFiles.count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.fill.tertiary, in: .capsule)
                }

                Menu {
                    Button(action: { viewModel.toggleAllStaging() }) {
                        let allStaged = viewModel.changedFiles.allSatisfy(\.isStaged)
                        Label(allStaged ? "Deselect All" : "Select All",
                              systemImage: allStaged ? "square" : "checkmark.square")
                    }
                    Divider()
                    Button(role: .destructive, action: {
                        withAnimation { appState.removeRepository(id: repository.id) }
                    }) {
                        Label("Remove Repository", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20)
            }
        }
    }

    @Environment(AppState.self) private var appState
}
