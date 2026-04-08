import SwiftUI

struct BranchPickerView: View {
    @Bindable var viewModel: RepositoryViewModel
    @State private var showPopover = false
    @State private var showNewBranch = false
    @State private var showMerge = false

    var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "arrow.triangle.branch")
                    .imageScale(.small)
                Text(viewModel.currentBranch.isEmpty ? "–" : viewModel.currentBranch)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 160)
                if viewModel.isSwitchingBranch || viewModel.isFetching {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.subheadline)
        }
        .buttonStyle(.accessoryBar)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            BranchListPopover(
                viewModel: viewModel,
                isPresented: $showPopover,
                showNewBranch: $showNewBranch,
                showMerge: $showMerge
            )
        }
        .popover(isPresented: $showNewBranch, arrowEdge: .bottom) {
            NewBranchPopover(viewModel: viewModel, isPresented: $showNewBranch)
        }
        .popover(isPresented: $showMerge, arrowEdge: .bottom) {
            MergeBranchPopover(viewModel: viewModel, isPresented: $showMerge)
        }
        .onAppear {
            Task { await viewModel.refreshBranches() }
        }
    }
}

// MARK: - Branch List Popover

private struct BranchListPopover: View {
    let viewModel: RepositoryViewModel
    @Binding var isPresented: Bool
    @Binding var showNewBranch: Bool
    @Binding var showMerge: Bool
    @State private var searchText = ""

    private var filteredLocalBranches: [String] {
        guard !searchText.isEmpty else { return viewModel.localBranches }
        return viewModel.localBranches.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredRemoteBranches: [String] {
        guard !searchText.isEmpty else { return viewModel.remoteBranches }
        return viewModel.remoteBranches.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("Filter branches…", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)

            Divider()

            // Branch list
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !filteredLocalBranches.isEmpty {
                        sectionHeader("Local Branches")

                        ForEach(filteredLocalBranches, id: \.self) { branch in
                            BranchRow(
                                name: branch,
                                isCurrent: branch == viewModel.currentBranch,
                                icon: "arrow.triangle.branch"
                            ) {
                                guard branch != viewModel.currentBranch else { return }
                                isPresented = false
                                Task { await viewModel.checkoutBranch(branch) }
                            }
                        }
                    }

                    if !filteredRemoteBranches.isEmpty {
                        sectionHeader("Remote Branches")

                        ForEach(filteredRemoteBranches, id: \.self) { branch in
                            BranchRow(
                                name: branch,
                                isCurrent: false,
                                icon: "globe"
                            ) {
                                let localName = branch.components(separatedBy: "/")
                                    .dropFirst().joined(separator: "/")
                                isPresented = false
                                Task { await viewModel.checkoutBranch(localName) }
                            }
                        }
                    }

                    if filteredLocalBranches.isEmpty && filteredRemoteBranches.isEmpty {
                        Text("No matching branches")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                }
            }
            .frame(maxHeight: 300)

            Divider()

            // Actions
            HStack(spacing: 0) {
                Button {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showNewBranch = true
                    }
                } label: {
                    Label("New Branch", systemImage: "plus")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)

                Divider()
                    .frame(height: 16)

                Button {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showMerge = true
                    }
                } label: {
                    Label("Merge", systemImage: "arrow.triangle.merge")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)

                Divider()
                    .frame(height: 16)

                Button {
                    Task { await viewModel.fetchRemote() }
                } label: {
                    Label("Fetch", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isFetching)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(width: 280)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }
}

// MARK: - Branch Row

private struct BranchRow: View {
    let name: String
    let isCurrent: Bool
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                    .imageScale(.small)

                Text(name)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                if isCurrent {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .imageScale(.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isCurrent ? Color.accentColor.opacity(0.08) : .clear)
    }
}

// MARK: - New Branch Popover

private struct NewBranchPopover: View {
    let viewModel: RepositoryViewModel
    @Binding var isPresented: Bool
    @State private var branchName = ""
    @FocusState private var isFocused: Bool

    private var isValid: Bool {
        let name = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && !name.contains(" ") && !viewModel.localBranches.contains(name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Branch")
                .font(.headline)

            Label("From: \(viewModel.currentBranch)", systemImage: "arrow.triangle.branch")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Branch name", text: $branchName)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    createBranch()
                }

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createBranch()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            isFocused = true
        }
    }

    private func createBranch() {
        guard isValid else { return }
        let name = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await viewModel.createAndCheckoutBranch(name)
            isPresented = false
        }
    }
}

// MARK: - Merge Branch Popover

private struct MergeBranchPopover: View {
    let viewModel: RepositoryViewModel
    @Binding var isPresented: Bool
    @State private var selectedBranch: String?
    @State private var searchText = ""

    private var mergeCandidates: [String] {
        let all = viewModel.localBranches.filter { $0 != viewModel.currentBranch }
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Merge into \(viewModel.currentBranch)")
                    .font(.headline)

                Text("Choose a branch to merge into the current branch.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("Filter branches…", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(mergeCandidates, id: \.self) { branch in
                        Button {
                            selectedBranch = branch
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 16)
                                    .imageScale(.small)

                                Text(branch)
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                Spacer()

                                if selectedBranch == branch {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .imageScale(.small)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(selectedBranch == branch ? Color.accentColor.opacity(0.08) : .clear)
                    }

                    if mergeCandidates.isEmpty {
                        Text("No branches to merge")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                }
            }
            .frame(maxHeight: 200)

            Divider()

            HStack {
                if let selected = selectedBranch {
                    Label {
                        Text("\(selected)")
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } icon: {
                        Image(systemName: "arrow.triangle.merge")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Merge") {
                    guard let branch = selectedBranch else { return }
                    Task {
                        await viewModel.mergeBranch(branch)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedBranch == nil)
            }
            .padding(12)
        }
        .frame(width: 300)
    }
}
