import SwiftUI
import CodeEditLanguages

@Observable
final class EditorSession: Identifiable {
    let id: UUID
    let relativePath: String
    var content: String
    var hasUnsavedChanges: Bool = false
    var isLoading: Bool = true
    let repositoryPath: URL

    var fileName: String {
        URL(fileURLWithPath: relativePath).lastPathComponent
    }

    var fileExtension: String {
        URL(fileURLWithPath: relativePath).pathExtension
    }

    var language: CodeLanguage {
        let url = repositoryPath.appendingPathComponent(relativePath)
        return CodeLanguage.detectLanguageFrom(url: url)
    }

    init(id: UUID = UUID(), relativePath: String, content: String, repositoryPath: URL) {
        self.id = id
        self.relativePath = relativePath
        self.content = content
        self.repositoryPath = repositoryPath
    }

    func save() {
        let fullURL = repositoryPath.appendingPathComponent(relativePath)
        do {
            try content.write(to: fullURL, atomically: true, encoding: .utf8)
            hasUnsavedChanges = false
        } catch {
            // Error handled by caller
        }
    }
}
