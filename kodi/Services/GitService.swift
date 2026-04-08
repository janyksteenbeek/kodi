import Foundation

enum GitError: LocalizedError {
    case commandFailed(String)
    case notARepository

    var errorDescription: String? {
        switch self {
        case .commandFailed(let output): "Git command failed: \(output)"
        case .notARepository: "Not a git repository"
        }
    }
}

final class GitService: Sendable {

    nonisolated func isGitRepository(at path: URL) async -> Bool {
        do {
            let output = try await runGit(["rev-parse", "--is-inside-work-tree"], at: path)
            return output.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
        } catch {
            return false
        }
    }

    nonisolated func status(at repositoryPath: URL) async throws -> [ChangedFile] {
        let output = try await runGit(["status", "--porcelain=v1"], at: repositoryPath)
        guard !output.isEmpty else { return [] }

        return output.components(separatedBy: "\n").compactMap { line in
            guard line.count >= 4 else { return nil }
            let indexStatus = line[line.startIndex]
            let worktreeStatus = line[line.index(after: line.startIndex)]

            var filePath = String(line.dropFirst(3))
            var oldPath: String? = nil

            // Handle renames: "R  old -> new"
            if filePath.contains(" -> ") {
                let parts = filePath.components(separatedBy: " -> ")
                oldPath = parts[0]
                filePath = parts[1]
            }

            let isStaged: Bool
            let status: ChangedFile.FileStatus

            if indexStatus == "?" {
                status = .untracked
                isStaged = false
            } else if indexStatus != " " {
                // Staged change
                status = parseStatus(indexStatus)
                isStaged = true
            } else {
                // Unstaged change
                status = parseStatus(worktreeStatus)
                isStaged = false
            }

            return ChangedFile(
                path: filePath,
                status: status,
                isStaged: isStaged,
                oldPath: oldPath
            )
        }
    }

    nonisolated func diff(at repositoryPath: URL, file: String? = nil, staged: Bool = false) async throws -> String {
        var args = ["diff"]
        if staged { args.append("--cached") }
        args.append("--no-color")
        if let file { args.append(file) }
        return try await runGit(args, at: repositoryPath)
    }

    nonisolated func diffAll(at repositoryPath: URL) async throws -> String {
        // Get both staged and unstaged diffs
        let unstaged = try await runGit(["diff", "--no-color"], at: repositoryPath)
        let staged = try await runGit(["diff", "--cached", "--no-color"], at: repositoryPath)

        if unstaged.isEmpty { return staged }
        if staged.isEmpty { return unstaged }
        return unstaged + "\n" + staged
    }

    nonisolated func stage(files: [String], at repositoryPath: URL) async throws {
        guard !files.isEmpty else { return }
        var args = ["add"]
        args.append(contentsOf: files)
        _ = try await runGit(args, at: repositoryPath)
    }

    nonisolated func unstage(files: [String], at repositoryPath: URL) async throws {
        guard !files.isEmpty else { return }
        var args = ["reset", "HEAD"]
        args.append(contentsOf: files)
        _ = try await runGit(args, at: repositoryPath)
    }

    nonisolated func commit(message: String, at repositoryPath: URL) async throws {
        _ = try await runGit(["commit", "-m", message], at: repositoryPath)
    }

    nonisolated func push(at repositoryPath: URL) async throws {
        _ = try await runGit(["push"], at: repositoryPath)
    }

    nonisolated func pull(at repositoryPath: URL) async throws {
        _ = try await runGit(["pull"], at: repositoryPath)
    }

    nonisolated func hasRemote(at repositoryPath: URL) async -> Bool {
        do {
            let output = try await runGit(["remote"], at: repositoryPath)
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }

    nonisolated func aheadBehind(at repositoryPath: URL) async -> (ahead: Int, behind: Int) {
        do {
            let output = try await runGit(["rev-list", "--left-right", "--count", "@{upstream}...HEAD"], at: repositoryPath)
            let parts = output.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\t")
            guard parts.count == 2,
                  let behind = Int(parts[0]),
                  let ahead = Int(parts[1]) else { return (0, 0) }
            return (ahead, behind)
        } catch {
            return (0, 0)
        }
    }

    nonisolated func diffForFile(at repositoryPath: URL, file: String, staged: Bool) async throws -> String {
        var args = ["diff", "--no-color"]
        if staged { args.append("--cached") }
        args.append("--")
        args.append(file)
        return try await runGit(args, at: repositoryPath)
    }

    nonisolated func diffUntrackedFile(at repositoryPath: URL, file: String) async throws -> String {
        // For untracked files, show the full file content as additions
        let fullPath = repositoryPath.appendingPathComponent(file).path
        guard let data = FileManager.default.contents(atPath: fullPath),
              let content = String(data: data, encoding: .utf8) else {
            return ""
        }
        let lines = content.components(separatedBy: "\n")
        var diff = "diff --git a/\(file) b/\(file)\n"
        diff += "new file mode 100644\n"
        diff += "--- /dev/null\n"
        diff += "+++ b/\(file)\n"
        diff += "@@ -0,0 +1,\(lines.count) @@\n"
        diff += lines.map { "+\($0)" }.joined(separator: "\n")
        return diff
    }

    nonisolated func listAllFiles(at repositoryPath: URL) async throws -> [String] {
        let tracked = try await runGit(["ls-files"], at: repositoryPath)
        let untracked = try await runGit(["ls-files", "--others", "--exclude-standard"], at: repositoryPath)

        let combined = (tracked + "\n" + untracked)
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(Set(combined)).sorted()
    }

    // MARK: - Branches

    nonisolated func currentBranch(at repositoryPath: URL) async throws -> String {
        let output = try await runGit(["rev-parse", "--abbrev-ref", "HEAD"], at: repositoryPath)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated func localBranches(at repositoryPath: URL) async throws -> [String] {
        let output = try await runGit(["branch", "--format=%(refname:short)"], at: repositoryPath)
        return output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    nonisolated func remoteBranches(at repositoryPath: URL) async throws -> [String] {
        let output = try await runGit(["branch", "-r", "--format=%(refname:short)"], at: repositoryPath)
        return output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasSuffix("/HEAD") }
    }

    nonisolated func checkout(branch: String, at repositoryPath: URL) async throws {
        _ = try await runGit(["checkout", branch], at: repositoryPath)
    }

    nonisolated func createBranch(name: String, at repositoryPath: URL) async throws {
        _ = try await runGit(["checkout", "-b", name], at: repositoryPath)
    }

    nonisolated func fetch(at repositoryPath: URL) async throws {
        _ = try await runGit(["fetch", "--all", "--prune"], at: repositoryPath)
    }

    // MARK: - Private

    nonisolated private func runGit(_ arguments: [String], at directory: URL) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        // Drain both pipes concurrently while the process is running. If we
        // waited until termination to read (as the previous implementation
        // did), large outputs would fill the ~64 KB pipe buffer, block git
        // on write, and cause an indefinite deadlock — the very symptom
        // behind "refresh loads forever" for repos with any sizeable diff.
        async let stdoutData: Data = Task.detached(priority: .userInitiated) {
            stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        }.value
        async let stderrData: Data = Task.detached(priority: .userInitiated) {
            stderrPipe.fileHandleForReading.readDataToEndOfFile()
        }.value

        let (stdoutBytes, stderrBytes) = await (stdoutData, stderrData)
        process.waitUntilExit()

        let stdout = String(data: stdoutBytes, encoding: .utf8) ?? ""
        let stderr = String(data: stderrBytes, encoding: .utf8) ?? ""

        if process.terminationStatus == 0 {
            return stdout
        } else {
            throw GitError.commandFailed(stderr.isEmpty ? stdout : stderr)
        }
    }

    nonisolated private func parseStatus(_ char: Character) -> ChangedFile.FileStatus {
        switch char {
        case "M": .modified
        case "A": .added
        case "D": .deleted
        case "R": .renamed
        case "C": .copied
        case "?": .untracked
        default: .modified
        }
    }
}
