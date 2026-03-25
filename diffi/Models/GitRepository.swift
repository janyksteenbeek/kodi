import Foundation

struct GitRepository: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var path: URL
    var bookmarkData: Data?

    var displayName: String {
        name.isEmpty ? path.lastPathComponent : name
    }

    init(id: UUID = UUID(), name: String = "", path: URL, bookmarkData: Data? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.bookmarkData = bookmarkData
    }
}
