import SwiftUI

struct CommitView: View {
    @Bindable var viewModel: RepositoryViewModel

    private var canCommit: Bool {
        !viewModel.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && viewModel.stagedCount > 0
        && !viewModel.isLoading
    }

    var body: some View {
        VStack(spacing: 10) {
            TextField("Commit message…", text: $viewModel.commitMessage, axis: .vertical)
                .lineLimit(2...5)
                .textFieldStyle(.roundedBorder)

            if let error = viewModel.error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 6) {
                if viewModel.hasRemote {
                    Button("Pull", systemImage: "arrow.down") {
                        Task { await viewModel.pull() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isSyncing)

                    Button("Push", systemImage: "arrow.up") {
                        Task { await viewModel.push() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isSyncing)
                }

                Spacer()

                Button {
                    Task { await viewModel.commit() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Commit (\(viewModel.stagedCount))")
                            .monospacedDigit()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canCommit)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider() }
    }
}
