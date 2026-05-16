import Foundation

struct Commit: Identifiable, Hashable, Sendable {
    let sha: String
    let authorName: String
    let authorEmail: String
    let date: Date
    let subject: String
    let body: String

    var id: String { sha }
    var shortSHA: String { String(sha.prefix(7)) }
}
