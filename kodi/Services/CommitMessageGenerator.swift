import Foundation
import FoundationModels

@available(macOS 26.0, *)
final class CommitMessageGenerator: Sendable {

    func generate(diff: String, stagedFiles: [ChangedFile]) async throws -> String {
        let instructions = """
        You generate concise git commit messages following the Conventional Commits format.

        Rules:
        - Use a type prefix: feat, fix, refactor, style, docs, test, chore, perf, ci, build
        - Format: type: short description
        - Optionally add a scope: type(scope): short description
        - Use lowercase, no period at end
        - Keep the first line under 72 characters
        - Be specific about what changed, focus on the "why" not the "what"
        - Only output the commit message, nothing else — no quotes, no backticks, no explanation
        """

        let session = LanguageModelSession(instructions: instructions)

        var prompt = "Staged files:\n"
        for file in stagedFiles {
            prompt += "- \(file.status.displayName): \(file.path)\n"
        }
        prompt += "\nDiff:\n"

        // Truncate diff to stay within on-device model context limits
        let maxDiffLength = 4000
        if diff.count > maxDiffLength {
            prompt += String(diff.prefix(maxDiffLength))
            prompt += "\n... (diff truncated)"
        } else {
            prompt += diff
        }

        let response = try await session.respond(to: prompt)

        // Clean up any accidental formatting from the model
        var message = response.content
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip wrapping quotes
        if message.hasPrefix("\"") && message.hasSuffix("\"") {
            message = String(message.dropFirst().dropLast())
        }

        // Strip wrapping backticks
        if message.hasPrefix("`") && message.hasSuffix("`") {
            message = String(message.dropFirst().dropLast())
        }

        return message
    }
}
