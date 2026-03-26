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
            // Select all + staging count
            if !viewModel.changedFiles.isEmpty {
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
            }

            // Commit message
            TextField("Commit message…", text: $viewModel.commitMessage, axis: .vertical)
                .lineLimit(2...5)
                .textFieldStyle(.roundedBorder)
                .font(.body)

            // Error
            if let error = viewModel.error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Commit + Push/Pull
            HStack(spacing: 6) {
                Button(action: { Task { await viewModel.commit() } }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Commit")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canCommit)
                .keyboardShortcut(.return, modifiers: .command)

                if viewModel.hasRemote {
                    Button(action: { Task { await viewModel.pull() } }) {
                        Image(systemName: "arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isSyncing)
                    .help("Pull")
                    .overlay(alignment: .topTrailing) {
                        if viewModel.commitsBehind > 0 {
                            badge(viewModel.commitsBehind)
                        }
                    }

                    Button(action: { Task { await viewModel.push() } }) {
                        Image(systemName: "arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isSyncing)
                    .help("Push")
                    .overlay(alignment: .topTrailing) {
                        if viewModel.commitsAhead > 0 {
                            badge(viewModel.commitsAhead)
                        }
                    }
                }
            }
            .controlSize(.large)
        }
        .padding(12)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private func badge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(.red, in: .capsule)
            .offset(x: 4, y: -4)
    }
}
