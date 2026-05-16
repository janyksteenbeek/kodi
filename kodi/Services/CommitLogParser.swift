import Foundation

enum CommitLogParser {
    static func parse(_ raw: String) -> [Commit] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let recordSeparator: Character = "\u{1e}"
        let fieldSeparator: Character = "\u{1f}"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        return trimmed.split(separator: recordSeparator, omittingEmptySubsequences: true).compactMap { record in
            let cleaned = record.drop(while: { $0 == "\n" || $0 == "\r" })
            let fields = cleaned.split(separator: fieldSeparator, maxSplits: 5, omittingEmptySubsequences: false)
            guard fields.count >= 6 else { return nil }

            let sha = String(fields[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            let authorName = String(fields[1])
            let authorEmail = String(fields[2])
            let dateString = String(fields[3])
            let subject = String(fields[4])
            let body = String(fields[5]).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !sha.isEmpty else { return nil }
            let date = formatter.date(from: dateString) ?? Date(timeIntervalSince1970: 0)

            return Commit(
                sha: sha,
                authorName: authorName,
                authorEmail: authorEmail,
                date: date,
                subject: subject,
                body: body
            )
        }
    }
}
