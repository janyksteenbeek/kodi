import Foundation

struct BookmarkManager {
    private static let bookmarksKey = "savedRepositoryBookmarks"

    static func saveBookmark(for url: URL) throws -> Data {
        let bookmarkData = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        return bookmarkData
    }

    static func resolveBookmark(_ data: Data) throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        if isStale {
            // Re-create bookmark if stale
            _ = try? saveBookmark(for: url)
        }
        return url
    }

    static func saveRepositories(_ repositories: [GitRepository]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(repositories) {
            UserDefaults.standard.set(data, forKey: bookmarksKey)
        }
    }

    static func loadRepositories() -> [GitRepository] {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([GitRepository].self, from: data)) ?? []
    }
}
