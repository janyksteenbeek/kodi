import SwiftUI

struct CommitView: View {
    @Bindable var viewModel: RepositoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .imageScale(.small)
                Text("\(viewModel.stagedCount) file\(viewModel.stagedCount == 1 ? "" : "s") selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField("Commit message…", text: $viewModel.commitMessage, axis: .vertical)
                .lineLimit(2...5)
                .textFieldStyle(.roundedBorder)
                .font(.body)

            if let error = viewModel.error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }

            Button(action: { Task { await viewModel.commit() } }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                    }
                    Text("Commit")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(
                viewModel.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || viewModel.stagedCount == 0
                || viewModel.isLoading
            )
            .keyboardShortcut(.return, modifiers: .command)
        }
    }
}
