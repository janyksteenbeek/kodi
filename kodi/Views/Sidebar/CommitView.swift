import SwiftUI

struct CommitView: View {
    @Bindable var viewModel: RepositoryViewModel

    private var allStaged: Bool {
        !viewModel.changedFiles.isEmpty && viewModel.changedFiles.allSatisfy(\.isStaged)
    }

    private var noneStaged: Bool {
        !viewModel.changedFiles.contains(where: \.isStaged)
    }

    private var checkboxImage: String {
        if allStaged { return "checkmark.circle.fill" }
        if noneStaged { return "circle" }
        return "minus.circle.fill"
    }

    private var canCommit: Bool {
        !viewModel.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && viewModel.stagedCount > 0
        && !viewModel.isLoading
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.toggleAllStaging()
                    }
                } label: {
                    Image(systemName: checkboxImage)
                        .foregroundStyle(noneStaged ? .secondary : Color.accentColor)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)

                Text("\(viewModel.stagedCount) of \(viewModel.changedFiles.count) staged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()
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
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: { Task { await viewModel.commit() } }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Commit")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canCommit)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(12)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
