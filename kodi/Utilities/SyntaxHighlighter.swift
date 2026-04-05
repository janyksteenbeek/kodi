import SwiftUI
import AppKit

struct SyntaxHighlighter {

    // Skip regex-based highlighting for very large files. The plain
    // monospaced text is still shown; this just prevents a multi-second
    // hang on the main thread when opening large source files.
    static let largeFileCharacterThreshold = 50_000
    static let largeFileLineThreshold = 2_000

    // MARK: - Token Types

    enum TokenType {
        case keyword
        case string
        case comment
        case number
        case type
        case attribute
        case preprocessor

        var color: Color {
            switch self {
            case .keyword:      Color(nsColor: .systemPink)
            case .string:       Color(nsColor: .systemOrange)
            case .comment:      Color.secondary
            case .number:       Color(nsColor: .systemBlue)
            case .type:         Color(nsColor: .systemTeal)
            case .attribute:    Color(nsColor: .systemPurple)
            case .preprocessor: Color(nsColor: .systemBrown)
            }
        }

        var nsColor: NSColor {
            switch self {
            case .keyword:      .systemPink
            case .string:       .systemOrange
            case .comment:      .secondaryLabelColor
            case .number:       .systemBlue
            case .type:         .systemTeal
            case .attribute:    .systemPurple
            case .preprocessor: .systemBrown
            }
        }
    }

    // MARK: - Language Definition

    struct Language {
        let keywords: Set<String>
        let typeKeywords: Set<String>
        let lineComment: String?
        let blockComment: (start: String, end: String)?
        let attributePattern: String?
        let preprocessorPattern: String?
        let variablePattern: String?

        init(keywords: Set<String>, typeKeywords: Set<String>, lineComment: String?,
             blockComment: (start: String, end: String)? = nil,
             attributePattern: String? = nil, preprocessorPattern: String? = nil,
             variablePattern: String? = nil) {
            self.keywords = keywords
            self.typeKeywords = typeKeywords
            self.lineComment = lineComment
            self.blockComment = blockComment
            self.attributePattern = attributePattern
            self.preprocessorPattern = preprocessorPattern
            self.variablePattern = variablePattern
        }
    }

    // MARK: - Public API

    static func highlight(_ code: String, fileExtension: String) -> AttributedString {
        var result = AttributedString(code)
        result.font = .body.monospaced()

        guard !code.isEmpty, let lang = language(for: fileExtension) else {
            return result
        }

        let nsCode = code as NSString
        let fullRange = NSRange(location: 0, length: nsCode.length)
        var protected = IndexSet()

        // Order matters: comments & strings first (take precedence over keywords)

        // 1. Block comments (/* ... */)
        if let bc = lang.blockComment {
            let startEsc = NSRegularExpression.escapedPattern(for: bc.start)
            let endEsc = NSRegularExpression.escapedPattern(for: bc.end)
            applyPattern(startEsc + "[\\s\\S]*?" + endEsc, to: &result, in: nsCode, range: fullRange, type: .comment, protected: &protected, options: .dotMatchesLineSeparators)
        }

        // 2. Line comments
        if let prefix = lang.lineComment {
            let pattern = NSRegularExpression.escapedPattern(for: prefix) + ".*$"
            applyPattern(pattern, to: &result, in: nsCode, range: fullRange, type: .comment, protected: &protected, options: .anchorsMatchLines)
        }

        // 3. Double-quoted strings
        applyPattern(#""(?:[^"\\]|\\.)*""#, to: &result, in: nsCode, range: fullRange, type: .string, protected: &protected)

        // 4. Single-quoted strings
        applyPattern(#"'(?:[^'\\]|\\.)*'"#, to: &result, in: nsCode, range: fullRange, type: .string, protected: &protected)

        // 5. Backtick strings (JS template literals, Go raw strings)
        applyPattern(#"`(?:[^`\\]|\\.)*`"#, to: &result, in: nsCode, range: fullRange, type: .string, protected: &protected)

        // 6. Preprocessor directives
        if let pp = lang.preprocessorPattern {
            applyPattern(pp, to: &result, in: nsCode, range: fullRange, type: .preprocessor, protected: &protected)
        }

        // 7. Attributes (@Something, #[...], etc.)
        if let attr = lang.attributePattern {
            applyPattern(attr, to: &result, in: nsCode, range: fullRange, type: .attribute, protected: &protected)
        }

        // 8. Variables ($var, etc.)
        if let vp = lang.variablePattern {
            applyPattern(vp, to: &result, in: nsCode, range: fullRange, type: .attribute, protected: &protected)
        }

        // 9. Numbers (hex, binary, octal, float, int)
        applyPattern(#"\b(?:0[xX][0-9a-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+|\d[\d_]*\.?[\d_]*(?:[eE][+-]?[\d_]+)?)\b"#, to: &result, in: nsCode, range: fullRange, type: .number, protected: &protected)

        // 10. Type keywords
        for typeKw in lang.typeKeywords {
            applyWord(typeKw, to: &result, in: nsCode, range: fullRange, type: .type, protected: &protected)
        }

        // 11. Keywords
        for kw in lang.keywords {
            applyWord(kw, to: &result, in: nsCode, range: fullRange, type: .keyword, protected: &protected)
        }

        // 12. PascalCase identifiers as types
        applyPattern(#"\b[A-Z][a-zA-Z0-9]+\b"#, to: &result, in: nsCode, range: fullRange, type: .type, protected: &protected)

        return result
    }

    // MARK: - NSAttributedString API (for NSTextView)

    static func highlightNS(_ code: String, fileExtension: String, font: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString(string: code, attributes: [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ])

        guard !code.isEmpty, let lang = language(for: fileExtension) else {
            return result
        }

        // Large-file gate: same spirit as DiffContentView's 500-line threshold.
        // Plain monospaced text is returned; user can still read/edit.
        if code.count > largeFileCharacterThreshold {
            return result
        }
        var newlineCount = 0
        for ch in code where ch == "\n" {
            newlineCount += 1
            if newlineCount > largeFileLineThreshold { return result }
        }

        let nsCode = code as NSString
        let fullRange = NSRange(location: 0, length: nsCode.length)
        var protected = IndexSet()

        if let bc = lang.blockComment {
            let startEsc = NSRegularExpression.escapedPattern(for: bc.start)
            let endEsc = NSRegularExpression.escapedPattern(for: bc.end)
            applyNSPattern(startEsc + "[\\s\\S]*?" + endEsc, to: result, in: nsCode, range: fullRange, type: .comment, protected: &protected, options: .dotMatchesLineSeparators)
        }

        if let prefix = lang.lineComment {
            let pattern = NSRegularExpression.escapedPattern(for: prefix) + ".*$"
            applyNSPattern(pattern, to: result, in: nsCode, range: fullRange, type: .comment, protected: &protected, options: .anchorsMatchLines)
        }

        applyNSPattern(#""(?:[^"\\]|\\.)*""#, to: result, in: nsCode, range: fullRange, type: .string, protected: &protected)
        applyNSPattern(#"'(?:[^'\\]|\\.)*'"#, to: result, in: nsCode, range: fullRange, type: .string, protected: &protected)
        applyNSPattern(#"`(?:[^`\\]|\\.)*`"#, to: result, in: nsCode, range: fullRange, type: .string, protected: &protected)

        if let pp = lang.preprocessorPattern {
            applyNSPattern(pp, to: result, in: nsCode, range: fullRange, type: .preprocessor, protected: &protected)
        }
        if let attr = lang.attributePattern {
            applyNSPattern(attr, to: result, in: nsCode, range: fullRange, type: .attribute, protected: &protected)
        }
        if let vp = lang.variablePattern {
            applyNSPattern(vp, to: result, in: nsCode, range: fullRange, type: .attribute, protected: &protected)
        }

        applyNSPattern(#"\b(?:0[xX][0-9a-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+|\d[\d_]*\.?[\d_]*(?:[eE][+-]?[\d_]+)?)\b"#, to: result, in: nsCode, range: fullRange, type: .number, protected: &protected)

        for typeKw in lang.typeKeywords {
            applyNSWord(typeKw, to: result, in: nsCode, range: fullRange, type: .type, protected: &protected)
        }
        for kw in lang.keywords {
            applyNSWord(kw, to: result, in: nsCode, range: fullRange, type: .keyword, protected: &protected)
        }

        applyNSPattern(#"\b[A-Z][a-zA-Z0-9]+\b"#, to: result, in: nsCode, range: fullRange, type: .type, protected: &protected)

        return result
    }

    private static func applyNSPattern(
        _ pattern: String,
        to result: NSMutableAttributedString,
        in nsCode: NSString,
        range: NSRange,
        type: TokenType,
        protected: inout IndexSet,
        options: NSRegularExpression.Options = []
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let matches = regex.matches(in: nsCode as String, range: range)

        for match in matches {
            let r = match.range
            guard r.length > 0 else { continue }
            let intRange = r.location..<(r.location + r.length)
            if !protected.intersection(IndexSet(integersIn: intRange)).isEmpty { continue }
            result.addAttribute(.foregroundColor, value: type.nsColor, range: r)
            protected.insert(integersIn: intRange)
        }
    }

    private static func applyNSWord(
        _ word: String,
        to result: NSMutableAttributedString,
        in nsCode: NSString,
        range: NSRange,
        type: TokenType,
        protected: inout IndexSet
    ) {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: word) + "\\b"
        applyNSPattern(pattern, to: result, in: nsCode, range: range, type: type, protected: &protected)
    }

    // MARK: - Pattern Matching

    private static func applyPattern(
        _ pattern: String,
        to result: inout AttributedString,
        in nsCode: NSString,
        range: NSRange,
        type: TokenType,
        protected: inout IndexSet,
        options: NSRegularExpression.Options = []
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let matches = regex.matches(in: nsCode as String, range: range)

        for match in matches {
            let r = match.range
            guard r.length > 0 else { continue }
            let intRange = r.location..<(r.location + r.length)

            if !protected.intersection(IndexSet(integersIn: intRange)).isEmpty { continue }

            let start = result.index(result.startIndex, offsetByCharacters: r.location)
            let end = result.index(start, offsetByCharacters: r.length)
            result[start..<end].foregroundColor = type.color

            protected.insert(integersIn: intRange)
        }
    }

    private static func applyWord(
        _ word: String,
        to result: inout AttributedString,
        in nsCode: NSString,
        range: NSRange,
        type: TokenType,
        protected: inout IndexSet
    ) {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: word) + "\\b"
        applyPattern(pattern, to: &result, in: nsCode, range: range, type: type, protected: &protected)
    }

    // MARK: - Extension Mapping

    static func language(for ext: String) -> Language? {
        let ext = ext.lowercased()
        switch ext {
        case "swift":                       return swift
        case "py", "pyw":                   return python
        case "js", "mjs", "cjs", "jsx":     return javascript
        case "ts", "tsx", "mts":            return typescript
        case "go":                          return go
        case "rs":                          return rust
        case "rb", "rake", "gemspec":       return ruby
        case "java":                        return java
        case "kt", "kts":                   return kotlin
        case "c", "h":                      return cLang
        case "cpp", "cc", "cxx", "hpp", "hh", "hxx": return cpp
        case "cs":                          return csharp
        case "php":                         return php
        case "sh", "bash", "zsh", "fish":   return shell
        case "sql":                         return sql
        case "css", "scss", "less":         return css
        case "html", "htm", "xml", "svg":   return html
        case "json":                        return json
        case "yaml", "yml":                 return yaml
        case "toml":                        return toml
        case "md", "markdown":              return markdown
        case "lua":                         return lua
        case "r":                           return rLang
        case "dart":                        return dart
        case "ex", "exs":                   return elixir
        case "zig":                         return zig
        case "m", "mm":                     return objectiveC
        default:                            return nil
        }
    }

    // MARK: - Language Definitions

    private static let swift = Language(
        keywords: ["import", "func", "var", "let", "if", "else", "guard", "return", "switch", "case", "default",
                    "for", "in", "while", "repeat", "break", "continue", "class", "struct", "enum", "protocol",
                    "extension", "init", "deinit", "self", "super", "nil", "true", "false", "throws", "throw",
                    "try", "catch", "as", "is", "where", "typealias", "associatedtype", "static", "private",
                    "fileprivate", "internal", "public", "open", "override", "mutating", "nonmutating", "lazy",
                    "weak", "unowned", "defer", "async", "await", "actor", "some", "any", "consuming", "borrowing",
                    "nonisolated", "do", "willSet", "didSet", "get", "set", "inout", "operator", "subscript",
                    "convenience", "required", "final", "indirect", "precedencegroup", "macro"],
        typeKeywords: ["Int", "String", "Bool", "Double", "Float", "Array", "Dictionary", "Set", "Optional",
                       "Result", "Void", "Never", "Any", "AnyObject", "Error", "Codable", "Hashable",
                       "Equatable", "Identifiable", "Sendable", "View", "ObservableObject", "Published",
                       "State", "Binding", "Environment", "Observable"],
        lineComment: "//",
        blockComment: ("/*", "*/"),
        attributePattern: #"@[a-zA-Z_]\w*"#,
        preprocessorPattern: #"#(?:if|elseif|else|endif|selector|available|warning|error)\b"#
    )

    private static let python = Language(
        keywords: ["def", "class", "if", "elif", "else", "for", "while", "return", "import", "from", "as",
                    "try", "except", "finally", "raise", "with", "yield", "lambda", "pass", "break",
                    "continue", "and", "or", "not", "is", "in", "True", "False", "None", "global",
                    "nonlocal", "assert", "del", "async", "await", "match", "case", "type"],
        typeKeywords: ["int", "str", "float", "bool", "list", "dict", "set", "tuple", "bytes",
                       "object", "type", "Exception", "TypeError", "ValueError"],
        lineComment: "#",
        attributePattern: #"@[a-zA-Z_]\w*"#,
        preprocessorPattern: nil
    )

    private static let javascript = Language(
        keywords: ["function", "var", "let", "const", "if", "else", "for", "while", "do", "switch", "case",
                    "default", "break", "continue", "return", "throw", "try", "catch", "finally", "new",
                    "delete", "typeof", "instanceof", "void", "this", "class", "extends", "super", "import",
                    "export", "from", "async", "await", "yield", "of", "in", "true", "false", "null",
                    "undefined", "static", "get", "set"],
        typeKeywords: ["Array", "Object", "String", "Number", "Boolean", "Function", "Symbol", "Map",
                       "Set", "WeakMap", "WeakSet", "Promise", "Error", "RegExp", "Date", "JSON", "Math"],
        lineComment: "//",
        blockComment: ("/*", "*/")
    )

    private static let typescript = Language(
        keywords: javascript.keywords.union(["type", "interface", "enum", "namespace", "declare", "abstract",
                    "implements", "readonly", "as", "is", "keyof", "infer", "never", "unknown",
                    "any", "asserts", "override", "satisfies", "using"]),
        typeKeywords: javascript.typeKeywords.union(["Partial", "Required", "Readonly", "Record", "Pick",
                    "Omit", "Exclude", "Extract", "NonNullable", "ReturnType", "Parameters",
                    "Awaited", "Uppercase", "Lowercase"]),
        lineComment: "//",
        blockComment: ("/*", "*/"),
        attributePattern: #"@[a-zA-Z_]\w*"#
    )

    private static let go = Language(
        keywords: ["break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough",
                    "for", "func", "go", "goto", "if", "import", "interface", "map", "package", "range",
                    "return", "select", "struct", "switch", "type", "var", "nil", "true", "false", "iota"],
        typeKeywords: ["int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32",
                       "uint64", "float32", "float64", "complex64", "complex128", "byte", "rune",
                       "string", "bool", "error", "any", "comparable"],
        lineComment: "//",
        blockComment: ("/*", "*/")
    )

    private static let rust = Language(
        keywords: ["fn", "let", "mut", "const", "static", "if", "else", "match", "for", "while", "loop",
                    "break", "continue", "return", "struct", "enum", "impl", "trait", "type", "where",
                    "use", "mod", "pub", "crate", "super", "self", "Self", "as", "in", "ref", "move",
                    "async", "await", "dyn", "unsafe", "extern", "true", "false", "macro_rules"],
        typeKeywords: ["i8", "i16", "i32", "i64", "i128", "isize", "u8", "u16", "u32", "u64", "u128",
                       "usize", "f32", "f64", "bool", "char", "str", "String", "Vec", "Box", "Rc",
                       "Arc", "Option", "Result", "Some", "None", "Ok", "Err"],
        lineComment: "//",
        blockComment: ("/*", "*/"),
        attributePattern: #"#!?\[[\w:,()\s=\"]*\]"#
    )

    private static let ruby = Language(
        keywords: ["def", "end", "class", "module", "if", "elsif", "else", "unless", "case", "when",
                    "while", "until", "for", "do", "begin", "rescue", "ensure", "raise", "return",
                    "yield", "block_given?", "include", "extend", "require", "require_relative",
                    "attr_reader", "attr_writer", "attr_accessor", "self", "super", "nil", "true",
                    "false", "and", "or", "not", "then", "in", "puts", "print", "lambda", "proc"],
        typeKeywords: ["Integer", "Float", "String", "Array", "Hash", "Symbol", "Proc", "NilClass",
                       "TrueClass", "FalseClass", "IO", "File", "Regexp", "Range", "Struct"],
        lineComment: "#",
        variablePattern: #"@@?[a-zA-Z_]\w*|\$[a-zA-Z_]\w*"#
    )

    private static let java = Language(
        keywords: ["abstract", "assert", "boolean", "break", "byte", "case", "catch", "char", "class",
                    "const", "continue", "default", "do", "double", "else", "enum", "extends", "final",
                    "finally", "float", "for", "goto", "if", "implements", "import", "instanceof", "int",
                    "interface", "long", "native", "new", "package", "private", "protected", "public",
                    "return", "short", "static", "strictfp", "super", "switch", "synchronized", "this",
                    "throw", "throws", "transient", "try", "void", "volatile", "while", "var", "record",
                    "sealed", "permits", "yield", "true", "false", "null"],
        typeKeywords: ["String", "Integer", "Boolean", "Double", "Float", "Long", "Short", "Byte",
                       "Character", "Object", "List", "Map", "Set", "ArrayList", "HashMap", "Optional",
                       "Stream", "Collection", "Iterable", "Comparable", "Runnable"],
        lineComment: "//",
        blockComment: ("/*", "*/"),
        attributePattern: #"@[a-zA-Z_]\w*"#
    )

    private static let kotlin = Language(
        keywords: ["fun", "val", "var", "if", "else", "when", "for", "while", "do", "return", "break",
                    "continue", "class", "interface", "object", "enum", "sealed", "data", "abstract",
                    "open", "override", "private", "protected", "public", "internal", "companion",
                    "import", "package", "is", "as", "in", "by", "init", "constructor", "this", "super",
                    "throw", "try", "catch", "finally", "suspend", "coroutine", "inline", "reified",
                    "typealias", "true", "false", "null", "it", "lazy", "lateinit"],
        typeKeywords: ["Int", "Long", "Short", "Byte", "Float", "Double", "Boolean", "Char", "String",
                       "Unit", "Nothing", "Any", "Array", "List", "Map", "Set", "Pair", "Triple",
                       "MutableList", "MutableMap", "MutableSet", "Sequence"],
        lineComment: "//",
        blockComment: ("/*", "*/"),
        attributePattern: #"@[a-zA-Z_]\w*"#
    )

    private static let cLang = Language(
        keywords: ["auto", "break", "case", "char", "const", "continue", "default", "do", "double",
                    "else", "enum", "extern", "float", "for", "goto", "if", "inline", "int", "long",
                    "register", "restrict", "return", "short", "signed", "sizeof", "static", "struct",
                    "switch", "typedef", "union", "unsigned", "void", "volatile", "while",
                    "true", "false", "NULL"],
        typeKeywords: ["size_t", "ptrdiff_t", "int8_t", "int16_t", "int32_t", "int64_t",
                       "uint8_t", "uint16_t", "uint32_t", "uint64_t", "bool", "FILE"],
        lineComment: "//",
        blockComment: ("/*", "*/"),
        preprocessorPattern: #"#\s*(?:include|define|undef|ifdef|ifndef|if|elif|else|endif|pragma|error|warning)\b"#
    )

    private static let cpp = Language(
        keywords: cLang.keywords.union(["catch", "class", "constexpr", "consteval", "constinit", "co_await",
                    "co_return", "co_yield", "decltype", "delete", "dynamic_cast", "explicit", "export",
                    "friend", "mutable", "namespace", "new", "noexcept", "operator", "override", "private",
                    "protected", "public", "reinterpret_cast", "requires", "static_assert", "static_cast",
                    "template", "this", "throw", "try", "typeid", "typename", "using", "virtual",
                    "concept", "nullptr", "final", "module", "import"]),
        typeKeywords: cLang.typeKeywords.union(["string", "vector", "map", "set", "unordered_map",
                    "unordered_set", "array", "unique_ptr", "shared_ptr", "weak_ptr", "optional",
                    "variant", "any", "span", "string_view", "tuple", "pair"]),
        lineComment: "//",
        attributePattern: nil,
        preprocessorPattern: cLang.preprocessorPattern
    )

    private static let csharp = Language(
        keywords: ["abstract", "as", "base", "bool", "break", "byte", "case", "catch", "char", "checked",
                    "class", "const", "continue", "decimal", "default", "delegate", "do", "double", "else",
                    "enum", "event", "explicit", "extern", "false", "finally", "fixed", "float", "for",
                    "foreach", "goto", "if", "implicit", "in", "int", "interface", "internal", "is", "lock",
                    "long", "namespace", "new", "null", "object", "operator", "out", "override", "params",
                    "private", "protected", "public", "readonly", "ref", "return", "sbyte", "sealed", "short",
                    "sizeof", "stackalloc", "static", "string", "struct", "switch", "this", "throw", "true",
                    "try", "typeof", "uint", "ulong", "unchecked", "unsafe", "ushort", "using", "var",
                    "virtual", "void", "volatile", "while", "async", "await", "record", "init", "required"],
        typeKeywords: ["String", "Int32", "Int64", "Boolean", "Double", "Single", "Decimal", "Object",
                       "List", "Dictionary", "Task", "IEnumerable", "Action", "Func", "Nullable",
                       "Span", "ReadOnlySpan", "ValueTask"],
        lineComment: "//",
        blockComment: ("/*", "*/"),
        attributePattern: #"\[[\w.,()\s=\"]*\]"#,
        preprocessorPattern: #"#\s*(?:if|elif|else|endif|define|undef|region|endregion|pragma|nullable)\b"#
    )

    private static let php = Language(
        keywords: ["function", "class", "interface", "trait", "enum", "extends", "implements", "abstract",
                    "final", "static", "public", "protected", "private", "readonly", "var", "const", "if",
                    "else", "elseif", "switch", "case", "default", "for", "foreach", "while", "do", "break",
                    "continue", "return", "throw", "try", "catch", "finally", "new", "use", "namespace",
                    "require", "include", "require_once", "include_once", "echo", "print", "die", "exit",
                    "true", "false", "null", "self", "parent", "this", "yield", "fn", "match", "as",
                    "instanceof", "array", "list", "isset", "unset", "empty"],
        typeKeywords: ["int", "float", "string", "bool", "array", "object", "callable", "iterable",
                       "void", "never", "mixed", "null"],
        lineComment: "//",
        blockComment: ("/*", "*/"),
        attributePattern: #"#\[[\w\\,()\s=\"]*\]"#,
        preprocessorPattern: #"<\?php\b|\?>"#,
        variablePattern: #"\$[a-zA-Z_]\w*"#
    )

    private static let shell = Language(
        keywords: ["if", "then", "else", "elif", "fi", "for", "while", "until", "do", "done", "case",
                    "esac", "in", "function", "return", "exit", "local", "export", "readonly", "declare",
                    "typeset", "unset", "shift", "source", "eval", "exec", "set", "true", "false",
                    "break", "continue", "select", "trap", "alias", "unalias"],
        typeKeywords: [],
        lineComment: "#",
        preprocessorPattern: #"^\s*#!"#,
        variablePattern: #"\$\{?[a-zA-Z_]\w*\}?"#
    )

    private static let sql = Language(
        keywords: ["SELECT", "FROM", "WHERE", "INSERT", "INTO", "UPDATE", "DELETE", "CREATE", "ALTER",
                    "DROP", "TABLE", "INDEX", "VIEW", "JOIN", "INNER", "LEFT", "RIGHT", "OUTER", "FULL",
                    "ON", "AND", "OR", "NOT", "IN", "IS", "NULL", "AS", "ORDER", "BY", "GROUP", "HAVING",
                    "LIMIT", "OFFSET", "UNION", "ALL", "DISTINCT", "SET", "VALUES", "BEGIN", "COMMIT",
                    "ROLLBACK", "TRANSACTION", "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "CONSTRAINT",
                    "DEFAULT", "CHECK", "UNIQUE", "CASCADE", "EXISTS", "BETWEEN", "LIKE", "ASC", "DESC",
                    "COUNT", "SUM", "AVG", "MIN", "MAX", "CASE", "WHEN", "THEN", "ELSE", "END", "WITH",
                    "RECURSIVE", "RETURNING", "CONFLICT", "REPLACE", "TRIGGER", "FUNCTION", "PROCEDURE",
                    // lowercase variants
                    "select", "from", "where", "insert", "into", "update", "delete", "create", "alter",
                    "drop", "table", "index", "view", "join", "inner", "left", "right", "outer", "full",
                    "on", "and", "or", "not", "in", "is", "null", "as", "order", "by", "group", "having",
                    "limit", "offset", "union", "all", "distinct", "set", "values", "begin", "commit",
                    "rollback", "primary", "key", "foreign", "references", "constraint", "default",
                    "check", "unique", "cascade", "exists", "between", "like", "asc", "desc",
                    "case", "when", "then", "else", "end", "with", "returning", "true", "false"],
        typeKeywords: ["INTEGER", "TEXT", "REAL", "BLOB", "BOOLEAN", "VARCHAR", "CHAR", "DECIMAL",
                       "NUMERIC", "DATE", "TIMESTAMP", "SERIAL", "BIGINT", "SMALLINT", "FLOAT",
                       "integer", "text", "real", "blob", "boolean", "varchar", "char", "decimal",
                       "numeric", "date", "timestamp", "serial", "bigint", "smallint", "float"],
        lineComment: "--",
        attributePattern: nil,
        preprocessorPattern: nil
    )

    private static let css = Language(
        keywords: ["important", "inherit", "initial", "unset", "revert", "none", "auto", "normal",
                    "bold", "italic", "solid", "dashed", "dotted", "block", "inline", "flex", "grid",
                    "absolute", "relative", "fixed", "sticky", "static", "hidden", "visible", "scroll",
                    "transparent", "currentColor"],
        typeKeywords: [],
        lineComment: nil,
        blockComment: ("/*", "*/"),
        preprocessorPattern: #"@(?:media|import|keyframes|font-face|supports|layer|property|container)\b"#
    )

    private static let html = Language(
        keywords: [],
        typeKeywords: [],
        lineComment: nil,
        attributePattern: #"\b[a-zA-Z-]+(?=\s*=)"#,
        preprocessorPattern: #"</?[a-zA-Z][\w-]*|/?>"#
    )

    private static let json = Language(
        keywords: ["true", "false", "null"],
        typeKeywords: [],
        lineComment: nil,
        attributePattern: #""[^"]*"\s*(?=:)"#,
        preprocessorPattern: nil
    )

    private static let yaml = Language(
        keywords: ["true", "false", "null", "yes", "no", "on", "off"],
        typeKeywords: [],
        lineComment: "#",
        attributePattern: #"^[\w][\w\s.-]*(?=\s*:)"#,
        preprocessorPattern: nil
    )

    private static let toml = Language(
        keywords: ["true", "false"],
        typeKeywords: [],
        lineComment: "#",
        attributePattern: #"^[\w][\w.-]*(?=\s*=)"#,
        preprocessorPattern: #"\[[\w.\s\"]*\]"#
    )

    private static let markdown = Language(
        keywords: [],
        typeKeywords: [],
        lineComment: nil,
        attributePattern: nil,
        preprocessorPattern: #"^#{1,6}\s"#
    )

    private static let lua = Language(
        keywords: ["and", "break", "do", "else", "elseif", "end", "false", "for", "function", "goto",
                    "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true",
                    "until", "while"],
        typeKeywords: ["string", "table", "math", "io", "os", "coroutine", "debug", "package"],
        lineComment: "--",
        attributePattern: nil,
        preprocessorPattern: nil
    )

    private static let rLang = Language(
        keywords: ["if", "else", "for", "while", "repeat", "function", "return", "break", "next",
                    "in", "library", "require", "source", "TRUE", "FALSE", "NULL", "NA", "Inf", "NaN"],
        typeKeywords: ["integer", "double", "character", "logical", "complex", "raw", "list",
                       "data.frame", "matrix", "vector", "factor"],
        lineComment: "#",
        attributePattern: nil,
        preprocessorPattern: nil
    )

    private static let dart = Language(
        keywords: ["abstract", "as", "assert", "async", "await", "break", "case", "catch", "class",
                    "const", "continue", "default", "deferred", "do", "dynamic", "else", "enum",
                    "export", "extends", "extension", "external", "factory", "false", "final", "finally",
                    "for", "get", "if", "implements", "import", "in", "is", "late", "library", "mixin",
                    "new", "null", "on", "operator", "part", "required", "rethrow", "return", "sealed",
                    "set", "show", "static", "super", "switch", "sync", "this", "throw", "true", "try",
                    "typedef", "var", "void", "while", "with", "yield"],
        typeKeywords: ["int", "double", "String", "bool", "List", "Map", "Set", "Future", "Stream",
                       "Iterable", "num", "Object", "dynamic", "Function", "Type", "Symbol", "Null",
                       "Never", "Record"],
        lineComment: "//",
        attributePattern: #"@[a-zA-Z_]\w*"#,
        preprocessorPattern: nil
    )

    private static let elixir = Language(
        keywords: ["def", "defp", "defmodule", "defstruct", "defprotocol", "defimpl", "defmacro",
                    "defguard", "defdelegate", "do", "end", "if", "else", "unless", "case", "cond",
                    "when", "with", "for", "in", "fn", "raise", "rescue", "try", "catch", "after",
                    "receive", "send", "spawn", "import", "use", "alias", "require", "true", "false",
                    "nil", "and", "or", "not", "is_nil"],
        typeKeywords: ["String", "Integer", "Float", "Atom", "List", "Tuple", "Map", "MapSet",
                       "Keyword", "Agent", "Task", "GenServer", "Supervisor", "Enum", "Stream"],
        lineComment: "#",
        attributePattern: #"@[a-zA-Z_]\w*"#,
        preprocessorPattern: nil
    )

    private static let zig = Language(
        keywords: ["const", "var", "fn", "pub", "return", "if", "else", "while", "for", "break",
                    "continue", "switch", "unreachable", "defer", "errdefer", "try", "catch", "orelse",
                    "comptime", "inline", "export", "extern", "struct", "enum", "union", "error",
                    "test", "true", "false", "null", "undefined", "async", "await", "suspend",
                    "resume", "nosuspend", "threadlocal", "anyframe", "usingnamespace"],
        typeKeywords: ["u8", "u16", "u32", "u64", "u128", "i8", "i16", "i32", "i64", "i128",
                       "f16", "f32", "f64", "f128", "usize", "isize", "bool", "void", "noreturn",
                       "type", "anytype", "anyerror", "comptime_int", "comptime_float"],
        lineComment: "//",
        attributePattern: nil,
        preprocessorPattern: nil
    )

    private static let objectiveC = Language(
        keywords: cLang.keywords.union(["self", "super", "nil", "Nil", "YES", "NO", "id",
                    "@interface", "@implementation", "@end", "@protocol", "@property", "@synthesize",
                    "@dynamic", "@selector", "@class", "@try", "@catch", "@finally", "@throw",
                    "@autoreleasepool", "@synchronized", "@optional", "@required", "@public",
                    "@private", "@protected", "@package", "@encode", "@compatibility_alias",
                    "strong", "weak", "copy", "assign", "nonatomic", "atomic", "readonly", "readwrite",
                    "retain", "nullable", "nonnull"]),
        typeKeywords: cLang.typeKeywords.union(["NSString", "NSArray", "NSDictionary", "NSNumber",
                    "NSObject", "NSInteger", "NSUInteger", "CGFloat", "BOOL", "NSError", "NSURL",
                    "NSData", "NSDate", "NSSet", "NSMutableArray", "NSMutableDictionary",
                    "NSMutableString", "NSMutableSet", "UIView", "UIViewController",
                    "NSView", "NSViewController"]),
        lineComment: "//",
        attributePattern: nil,
        preprocessorPattern: cLang.preprocessorPattern
    )
}
