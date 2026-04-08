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
        // Check special filenames first (no extension)
        let name = URL(fileURLWithPath: fileName).lastPathComponent.lowercased()
        if let special = Self.specialFileSymbols[name] { return special }

        switch fileExtension {
        case "swift": return "swift"
        case "js", "jsx", "mjs", "cjs": return "text.page"
        case "ts", "tsx", "mts", "cts": return "text.page"
        case "json", "jsonc", "json5": return "curlybraces"
        case "md", "txt", "rtf", "doc", "docx": return "doc.plaintext"
        case "html", "htm", "xhtml": return "globe"
        case "css", "scss", "less", "sass", "styl": return "paintbrush"
        case "py", "pyw", "pyi": return "text.page.badge.magnifyingglass"
        case "rb", "erb", "gemspec": return "diamond"
        case "go": return "text.page"
        case "rs": return "gearshape"
        case "java", "kt", "kts", "groovy", "gradle": return "cup.and.saucer"
        case "c", "cpp", "h", "hpp", "cc", "cxx", "hxx", "m", "mm": return "chevron.left.forwardslash.chevron.right"
        case "sh", "zsh", "bash", "fish", "ps1", "psm1", "bat", "cmd": return "terminal"
        case "yml", "yaml", "toml", "ini", "cfg", "conf": return "list.bullet.rectangle"
        case "png", "jpg", "jpeg", "gif", "svg", "webp", "ico", "bmp", "tiff", "heic": return "photo"
        case "pdf": return "doc.richtext"
        case "zip", "tar", "gz", "bz2", "xz", "7z", "rar", "dmg", "iso": return "doc.zipper"
        case "lock": return "lock"
        case "env": return "key"
        case "xml", "plist", "xsd", "xsl", "xslt": return "text.page.badge.magnifyingglass"
        // PHP
        case "php", "phtml", "php3", "php4", "php5": return "server.rack"
        // .NET / C#
        case "cs": return "number"
        case "vb", "vbs": return "v.square"
        case "fs", "fsx", "fsi": return "f.square"
        case "cshtml", "razor", "aspx", "ascx", "master": return "globe.badge.chevron.backward"
        case "xaml": return "rectangle.on.rectangle"
        case "sln", "csproj", "vbproj", "fsproj": return "shippingbox"
        // Dart / Flutter
        case "dart": return "diamond.fill"
        // Lua
        case "lua": return "moon"
        // R
        case "r", "rmd": return "chart.bar"
        // Perl
        case "pl", "pm": return "p.square"
        // Scala
        case "scala", "sc": return "s.square"
        // Elixir / Erlang
        case "ex", "exs", "erl", "hrl": return "drop"
        // Haskell
        case "hs", "lhs": return "function"
        // Clojure
        case "clj", "cljs", "cljc", "edn": return "parentheses"
        // SQL
        case "sql", "sqlite", "db": return "cylinder"
        // GraphQL / Protobuf
        case "graphql", "gql": return "point.3.connected.trianglepath.dotted"
        case "proto": return "rectangle.3.group"
        // Docker
        case "dockerfile": return "shippingbox"
        // Terraform / HCL
        case "tf", "hcl", "tfvars": return "cloud"
        // Nix
        case "nix": return "snowflake"
        // Zig
        case "zig": return "bolt"
        // Video / Audio
        case "mp4", "mov", "avi", "mkv", "webm": return "film"
        case "mp3", "wav", "aac", "flac", "ogg", "m4a": return "waveform"
        // Fonts
        case "ttf", "otf", "woff", "woff2": return "textformat"
        // Certificates / security
        case "pem", "crt", "cer", "key", "p12", "pfx": return "lock.shield"
        // Log files
        case "log": return "text.line.last.and.arrowtriangle.forward"
        // Diff / Patch
        case "diff", "patch": return "plus.forwardslash.minus"
        default: return "doc"
        }
    }

    private static let specialFileSymbols: [String: String] = [
        "dockerfile": "shippingbox",
        "makefile": "hammer",
        "cmakelists.txt": "hammer",
        "gemfile": "diamond",
        "rakefile": "diamond",
        "podfile": "shippingbox",
        "cartfile": "shippingbox",
        "vagrantfile": "server.rack",
        "procfile": "terminal",
        "license": "doc.text",
        "licence": "doc.text",
        "readme.md": "book",
        "changelog.md": "clock",
        "contributing.md": "person.2",
        ".gitignore": "eye.slash",
        ".gitattributes": "gear",
        ".editorconfig": "gear",
        ".prettierrc": "paintbrush",
        ".eslintrc": "checkmark.circle",
        ".swiftlint.yml": "checkmark.circle",
        "package.json": "shippingbox",
        "tsconfig.json": "gearshape",
        "compose.yml": "shippingbox",
        "compose.yaml": "shippingbox",
        "docker-compose.yml": "shippingbox",
        "docker-compose.yaml": "shippingbox",
    ]

    private var iconColor: Color {
        let name = URL(fileURLWithPath: fileName).lastPathComponent.lowercased()
        if Self.specialFileColors[name] != nil { return Self.specialFileColors[name]! }

        switch fileExtension {
        case "swift": return .orange
        case "js", "jsx", "mjs", "cjs": return .yellow
        case "ts", "tsx", "mts", "cts": return .blue
        case "json", "jsonc", "json5": return .gray
        case "html", "htm", "xhtml": return .orange
        case "css", "scss", "less", "sass", "styl": return .blue
        case "py", "pyw", "pyi": return .green
        case "rb", "erb", "gemspec": return .red
        case "go": return .cyan
        case "rs": return .orange
        case "md", "txt": return .secondary
        case "php", "phtml": return .purple
        case "cs", "cshtml", "razor", "aspx": return .purple
        case "vb", "vbs": return .blue
        case "fs", "fsx", "fsi": return .cyan
        case "dart": return .cyan
        case "lua": return .blue
        case "r", "rmd": return .blue
        case "pl", "pm": return .indigo
        case "scala", "sc": return .red
        case "ex", "exs": return .purple
        case "erl", "hrl": return .red
        case "hs", "lhs": return .purple
        case "clj", "cljs", "cljc": return .green
        case "java", "kt", "kts", "groovy", "gradle": return .orange
        case "sql", "sqlite": return .yellow
        case "graphql", "gql": return .pink
        case "proto": return .green
        case "tf", "hcl", "tfvars": return .purple
        case "nix": return .cyan
        case "zig": return .orange
        case "sln", "csproj", "vbproj", "fsproj": return .purple
        case "xaml": return .blue
        case "yml", "yaml", "toml", "ini", "cfg", "conf": return .gray
        case "sh", "zsh", "bash", "fish": return .green
        case "ps1", "psm1", "bat", "cmd": return .blue
        case "c", "cpp", "cc", "cxx": return .blue
        case "h", "hpp", "hxx": return .purple
        case "m", "mm": return .orange
        case "log": return .gray
        case "diff", "patch": return .green
        default: return .secondary
        }
    }

    private static let specialFileColors: [String: Color] = [
        "dockerfile": .blue,
        "makefile": .orange,
        "gemfile": .red,
        "package.json": .green,
        ".gitignore": .orange,
        ".editorconfig": .gray,
    ]
}
