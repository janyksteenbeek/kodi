import SwiftUI

struct GlobalSearchView: View {
    @Bindable var viewModel: RepositoryViewModel
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isSearchFieldFocused: Bool

    private var results: [SearchResult] {
        guard !query.isEmpty else { return [] }
        return fuzzyMatch(query: query, in: viewModel.directoryFiles)
            .prefix(20)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.title3)

                TextField("Go to File…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        openSelected()
                    }
                    .onChange(of: query) {
                        selectedIndex = 0
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if !results.isEmpty {
                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                                SearchResultRow(result: result, isSelected: index == selectedIndex)
                                    .id(index)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        index == selectedIndex
                                            ? AnyShapeStyle(Color.accentColor.opacity(0.2))
                                            : AnyShapeStyle(.clear),
                                        in: RoundedRectangle(cornerRadius: 6)
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedIndex = index
                                        openSelected()
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                    }
                    .onChange(of: selectedIndex) { _, newValue in
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
                .frame(maxHeight: 300)
            } else if !query.isEmpty {
                Divider()
                Text("No results")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            query = ""
            selectedIndex = 0
            isSearchFieldFocused = true
            if viewModel.directoryFiles.isEmpty {
                Task { await viewModel.loadDirectoryTree() }
            }
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 { selectedIndex -= 1 }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < results.count - 1 { selectedIndex += 1 }
            return .handled
        }
        .onKeyPress(.escape) {
            viewModel.isGlobalSearchVisible = false
            return .handled
        }
    }

    private func openSelected() {
        guard !results.isEmpty, selectedIndex < results.count else { return }
        let path = results[selectedIndex].path
        viewModel.openFile(path)
        viewModel.isGlobalSearchVisible = false
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let result: SearchResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            FileIconView(fileName: result.fileName)

            VStack(alignment: .leading, spacing: 1) {
                Text(result.fileName)
                    .font(.body)
                    .lineLimit(1)

                if !result.directory.isEmpty {
                    Text(result.directory)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Fuzzy Match

struct SearchResult: Identifiable {
    let id: String
    let path: String
    let fileName: String
    let directory: String
    let fileExtension: String
    let score: Int
}

private func fuzzyMatch(query: String, in files: [String]) -> [SearchResult] {
    let queryLower = query.lowercased()
    let queryChars = Array(queryLower)

    guard !queryChars.isEmpty else { return [] }

    var scored: [SearchResult] = []

    for path in files {
        let pathLower = path.lowercased()
        let pathChars = Array(pathLower)

        // Check if all query characters appear in order
        var queryIdx = 0
        var matchPositions: [Int] = []

        for (i, char) in pathChars.enumerated() {
            if queryIdx < queryChars.count && char == queryChars[queryIdx] {
                matchPositions.append(i)
                queryIdx += 1
            }
        }

        guard queryIdx == queryChars.count else { continue }

        // Scoring: prefer matches in filename, consecutive matches, and shorter paths
        let fileName = (path as NSString).lastPathComponent
        let directory = (path as NSString).deletingLastPathComponent
        let fileNameLower = fileName.lowercased()
        let ext = (fileName as NSString).pathExtension

        var score = 0

        // Bonus for matching in filename vs directory
        let fileNameStart = path.count - fileName.count
        let filenameMatches = matchPositions.filter { $0 >= fileNameStart }.count
        score += filenameMatches * 10

        // Bonus for consecutive matches
        for i in 1..<matchPositions.count {
            if matchPositions[i] == matchPositions[i - 1] + 1 {
                score += 5
            }
        }

        // Bonus for matching at start of filename
        if fileNameLower.hasPrefix(queryLower) {
            score += 20
        }

        // Bonus for exact filename match
        if fileNameLower == queryLower || (fileNameLower as NSString).deletingPathExtension.lowercased() == queryLower {
            score += 30
        }

        // Penalty for longer paths (prefer shorter, more relevant)
        score -= path.count / 5

        // Bonus for matching at word boundaries (after / . - _)
        let boundaryChars: Set<Character> = ["/", ".", "-", "_"]
        for pos in matchPositions {
            if pos == 0 || (pos > 0 && boundaryChars.contains(pathChars[pos - 1])) {
                score += 3
            }
        }

        scored.append(SearchResult(
            id: path,
            path: path,
            fileName: fileName,
            directory: directory,
            fileExtension: ext,
            score: score
        ))
    }

    return scored.sorted { $0.score > $1.score }
}
