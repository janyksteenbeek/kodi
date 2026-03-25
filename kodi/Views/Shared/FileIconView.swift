import SwiftUI

struct FileIconView: View {
    let fileName: String

    var body: some View {
        Image(systemName: sfSymbol)
            .foregroundStyle(iconColor)
            .imageScale(.medium)
            .frame(width: 16)
    }

    private var fileExtension: String {
        URL(fileURLWithPath: fileName).pathExtension.lowercased()
    }

    private var sfSymbol: String {
        switch fileExtension {
        case "swift": "swift"
        case "js", "ts", "jsx", "tsx": "text.page"
        case "json": "curlybraces"
        case "md", "txt", "rtf": "doc.plaintext"
        case "html", "htm": "globe"
        case "css", "scss", "less": "paintbrush"
        case "py": "text.page.badge.magnifyingglass"
        case "rb": "diamond"
        case "go": "text.page"
        case "rs": "gearshape"
        case "java", "kt": "cup.and.saucer"
        case "c", "cpp", "h", "hpp": "chevron.left.forwardslash.chevron.right"
        case "sh", "zsh", "bash": "terminal"
        case "yml", "yaml", "toml": "list.bullet.rectangle"
        case "png", "jpg", "jpeg", "gif", "svg", "webp": "photo"
        case "pdf": "doc.richtext"
        case "zip", "tar", "gz": "doc.zipper"
        case "lock": "lock"
        case "env": "key"
        case "xml", "plist": "text.page.badge.magnifyingglass"
        default: "doc"
        }
    }

    private var iconColor: Color {
        switch fileExtension {
        case "swift": .orange
        case "js", "jsx": .yellow
        case "ts", "tsx": .blue
        case "json": .gray
        case "html", "htm": .orange
        case "css", "scss": .blue
        case "py": .green
        case "rb": .red
        case "go": .cyan
        case "rs": .orange
        case "md", "txt": .secondary
        default: .secondary
        }
    }
}
