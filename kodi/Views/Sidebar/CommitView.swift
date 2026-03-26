import SwiftUI

struct CommitView: View {
    @Bindable var viewModel: RepositoryViewModel

    private var canCommit: Bool {
        !viewModel.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && viewModel.stagedCount > 0
        && !viewModel.isLoading
    }

    private var allStaged: Bool {
        viewModel.changedFiles.allSatisfy(\.isStaged)
    }

    var body: some View {
        VStack(spacing: 8) {
            if !viewModel.changedFiles.isEmpty {
                HStack {
                    Button {
                        viewModel.setStaging(!allStaged, for: viewModel.changedFiles)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: allStaged ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(allStaged ? Color.accentColor : .secondary)
                            Text(allStaged ? "All staged" : "Stage all")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("\(viewModel.stagedCount)/\(viewModel.changedFiles.count) staged")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }

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
                    Button {
                        Task { await viewModel.pull() }
                    } label: {
                        if viewModel.commitsBehind > 0 {
                            Label("Pull \(viewModel.commitsBehind)", systemImage: "arrow.down")
                                .monospacedDigit()
                        } else {
                            Label("Pull", systemImage: "arrow.down")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isSyncing)

                    if viewModel.commitsAhead > 0 {
                        Button {
                            Task { await viewModel.push() }
                        } label: {
                            Label("Push \(viewModel.commitsAhead)", systemImage: "arrow.up")
                                .monospacedDigit()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isSyncing)
                    }
                }

                Spacer()

                Button {
                    Task { await viewModel.commit() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Commit")
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
