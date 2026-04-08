import SwiftUI

struct FileIconView: View {
    let fileName: String

    var body: some View {
        if let asset = languageAsset {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.quaternary)

                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .offset(x: 2, y: 2)
            }
            .frame(width: 18, height: 18)
        } else {
            Image(systemName: sfSymbol)
                .foregroundStyle(iconColor)
                .imageScale(.medium)
                .frame(width: 18)
        }
    }

    private var fileExtension: String {
        URL(fileURLWithPath: fileName).pathExtension.lowercased()
    }

    private var lowercaseName: String {
        URL(fileURLWithPath: fileName).lastPathComponent.lowercased()
    }

    // MARK: - Language Asset Mapping

    private var languageAsset: String? {
        // Special filenames
        if let asset = Self.specialFileAssets[lowercaseName] { return asset }

        switch fileExtension {
        // Swift / Apple
        case "swift": return "FileIcons/swift"
        case "m": return "FileIcons/objectivec"
        case "mm": return "FileIcons/objectivecpp"
        case "applescript": return "FileIcons/applescript"

        // Web fundamentals
        case "html", "htm", "xhtml": return "FileIcons/html"
        case "css": return "FileIcons/css"
        case "scss", "sass": return "FileIcons/sass"
        case "less": return "FileIcons/less"
        case "styl": return "FileIcons/stylus"

        // JavaScript ecosystem
        case "js", "mjs", "cjs": return "FileIcons/javascript"
        case "jsx": return "FileIcons/react"
        case "ts", "mts", "cts": return "FileIcons/typescript"
        case "tsx": return "FileIcons/react"
        case "vue": return "FileIcons/vue"
        case "svelte": return "FileIcons/svelte"
        case "coffee": return "FileIcons/coffeescript"
        case "ejs": return "FileIcons/ejs"

        // Data / Config
        case "json", "jsonc", "json5": return "FileIcons/json"
        case "yml", "yaml": return "FileIcons/yaml"
        case "toml": return "FileIcons/toml"
        case "xml", "xsd", "xsl", "xslt": return "FileIcons/markup"
        case "plist": return "FileIcons/settings"
        case "nunjucks", "njk": return "FileIcons/nunjucks"
        case "csv": return "FileIcons/excel"
        case "graphql", "gql": return "FileIcons/graphql"
        case "proto": return "FileIcons/proto"
        case "env": return "FileIcons/dotenv"

        // Python
        case "py", "pyw", "pyi": return "FileIcons/python"
        case "pyx": return "FileIcons/cython"
        case "ipynb": return "FileIcons/jupyter"

        // Ruby
        case "rb", "erb", "gemspec": return "FileIcons/ruby"

        // PHP
        case "php", "phtml", "php3", "php4", "php5": return "FileIcons/php"
        case "blade.php": return "FileIcons/blade"
        case "twig": return "FileIcons/twig"

        // JVM
        case "java": return "FileIcons/java"
        case "kt", "kts": return "FileIcons/kotlin"
        case "scala", "sc": return "FileIcons/scala"
        case "groovy": return "FileIcons/groovy"
        case "gradle": return "FileIcons/gradle"
        case "clj", "cljs", "cljc", "edn": return "FileIcons/clojure"

        // .NET
        case "cs": return "FileIcons/csharp"
        case "vb", "vbs": return "FileIcons/visualbasic"
        case "fs", "fsx", "fsi": return "FileIcons/fsharp"
        case "sln": return "FileIcons/visualstudio"
        case "csproj", "vbproj", "fsproj": return "FileIcons/dotnet"
        case "xaml": return "FileIcons/xaml"
        case "razor", "cshtml", "aspx": return "FileIcons/razor"

        // Systems
        case "c", "h": return "FileIcons/c"
        case "cpp", "cc", "cxx", "hpp", "hxx": return "FileIcons/cpp"
        case "rs": return "FileIcons/rust"
        case "go": return "FileIcons/go"
        case "zig": return "FileIcons/zig"
        case "nim": return "FileIcons/nim"

        // Functional
        case "hs", "lhs": return "FileIcons/haskell"
        case "ex", "exs": return "FileIcons/elixir"
        case "erl", "hrl": return "FileIcons/erlang"
        case "elm": return "FileIcons/elm"
        case "ml", "mli": return "FileIcons/ocaml"
        case "re", "rei": return "FileIcons/reason"
        case "res", "resi": return "FileIcons/rescript"
        case "ps": return "FileIcons/purescript"

        // Scripting
        case "lua": return "FileIcons/lua"
        case "pl", "pm": return "FileIcons/perl"
        case "r", "rmd": return "FileIcons/rlang"
        case "jl": return "FileIcons/julia"
        case "dart": return "FileIcons/dart"
        case "cr": return "FileIcons/crystal"

        // Shell
        case "sh", "bash", "zsh": return "FileIcons/shell"
        case "fish": return "FileIcons/fish"
        case "ps1", "psm1": return "FileIcons/powershell"

        // Markup / Docs
        case "md", "mdx": return "FileIcons/markdown"
        case "tex", "latex": return "FileIcons/tex"
        case "rst": return "FileIcons/rst"

        // DevOps / Infra
        case "tf", "hcl", "tfvars": return "FileIcons/terraform"
        case "nix": return "FileIcons/nix"

        // Database
        case "sql", "sqlite", "db": return "FileIcons/database"
        case "prisma": return "FileIcons/prisma"

        // Images
        case "png", "jpg", "jpeg", "gif", "bmp", "tiff", "heic", "webp": return "FileIcons/image"
        case "svg": return "FileIcons/svg"
        case "ico": return "FileIcons/favicon"
        case "pdf": return "FileIcons/pdf"

        // Media
        case "mp4", "mov", "avi", "mkv", "webm": return "FileIcons/video"
        case "mp3", "wav", "aac", "flac", "ogg", "m4a": return "FileIcons/audio"

        // Fonts
        case "ttf", "otf", "woff", "woff2": return "FileIcons/font"

        // Archives
        case "zip", "tar", "gz", "bz2", "xz", "7z", "rar": return "FileIcons/zip"

        // Config files
        case "lock": return "FileIcons/key"
        case "log": return "FileIcons/log"
        case "sol": return "FileIcons/solidity"
        case "wasm": return "FileIcons/wasm"

        default: return nil
        }
    }

    private static let specialFileAssets: [String: String] = [
        // Docker
        "dockerfile": "FileIcons/docker",
        "docker-compose.yml": "FileIcons/docker",
        "docker-compose.yaml": "FileIcons/docker",
        "compose.yml": "FileIcons/docker",
        "compose.yaml": "FileIcons/docker",
        ".dockerignore": "FileIcons/docker",
        // Ruby
        "gemfile": "FileIcons/ruby",
        "rakefile": "FileIcons/ruby",
        // Node / JS
        "package.json": "FileIcons/npm",
        "package-lock.json": "FileIcons/npm",
        "tsconfig.json": "FileIcons/typescript",
        ".babelrc": "FileIcons/babel",
        "babel.config.js": "FileIcons/babel",
        ".eslintrc": "FileIcons/eslint",
        ".eslintrc.js": "FileIcons/eslint",
        ".eslintrc.json": "FileIcons/eslint",
        "eslint.config.js": "FileIcons/eslint",
        "eslint.config.mjs": "FileIcons/eslint",
        ".prettierrc": "FileIcons/prettier",
        "prettier.config.js": "FileIcons/prettier",
        "webpack.config.js": "FileIcons/webpack",
        "vite.config.ts": "FileIcons/vitejs",
        "vite.config.js": "FileIcons/vitejs",
        "vitest.config.ts": "FileIcons/vitest",
        "next.config.js": "FileIcons/nextjs",
        "next.config.mjs": "FileIcons/nextjs",
        "tailwind.config.js": "FileIcons/tailwind",
        "tailwind.config.ts": "FileIcons/tailwind",
        "postcss.config.js": "FileIcons/postcss",
        "jest.config.js": "FileIcons/jest",
        "jest.config.ts": "FileIcons/jest",
        ".mocharc.yml": "FileIcons/mocha",
        "rollup.config.js": "FileIcons/rollup",
        "svelte.config.js": "FileIcons/svelte",
        "yarn.lock": "FileIcons/yarn",
        "pnpm-lock.yaml": "FileIcons/pnpm",
        ".npmrc": "FileIcons/npm",
        ".yarnrc": "FileIcons/yarn",
        ".nvmrc": "FileIcons/node",
        ".node-version": "FileIcons/node",
        // Build
        "makefile": "FileIcons/cmake",
        "cmakelists.txt": "FileIcons/cmake",
        "gulpfile.js": "FileIcons/gulp",
        "gruntfile.js": "FileIcons/grunt",
        // Git
        ".gitignore": "FileIcons/git",
        ".gitattributes": "FileIcons/git",
        ".gitmodules": "FileIcons/git",
        ".gitkeep": "FileIcons/git",
        // CI
        "jenkinsfile": "FileIcons/jenkins",
        ".gitlab-ci.yml": "FileIcons/gitlab",
        // Editor
        ".editorconfig": "FileIcons/editorconfig",
        // Firebase
        "firebase.json": "FileIcons/firebase",
        ".firebaserc": "FileIcons/firebase",
        // Storybook
        ".storybook": "FileIcons/storybook",
        // Misc
        "license": "FileIcons/certificate",
        "licence": "FileIcons/certificate",
        "readme.md": "FileIcons/markdown",
        "contributing.md": "FileIcons/contributing",
        ".env": "FileIcons/dotenv",
        ".env.local": "FileIcons/dotenv",
        ".env.development": "FileIcons/dotenv",
        ".env.production": "FileIcons/dotenv",
        "vercel.json": "FileIcons/vercel",
        ".sentryclirc": "FileIcons/sentry",
    ]

    // MARK: - SF Symbol Fallbacks (for types without custom icons)

    private var sfSymbol: String {
        switch fileExtension {
        case "txt", "rtf", "doc", "docx": return "doc.plaintext"
        case "bat", "cmd": return "terminal"
        case "ini", "cfg", "conf": return "list.bullet.rectangle"
        case "dmg", "iso": return "externaldrive"
        case "pem", "crt", "cer", "key", "p12", "pfx": return "lock.shield"
        case "diff", "patch": return "plus.forwardslash.minus"
        default: return "doc"
        }
    }

    private var iconColor: Color {
        switch fileExtension {
        case "txt", "rtf": return .secondary
        case "bat", "cmd": return .blue
        case "ini", "cfg", "conf": return .gray
        case "diff", "patch": return .green
        default: return .secondary
        }
    }
}
