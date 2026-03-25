import Foundation

struct DiffParser {
    static func parse(_ rawDiff: String) -> [DiffResult] {
        guard !rawDiff.isEmpty else { return [] }

        let lines = rawDiff.components(separatedBy: "\n")
        var results: [DiffResult] = []
        var currentFileLines: [String] = []
        var currentFilePath: String?
        var currentOldPath: String?

        for line in lines {
            if line.hasPrefix("diff --git ") {
                // Flush previous file
                if let path = currentFilePath {
                    let hunks = parseHunks(from: currentFileLines)
                    results.append(DiffResult(filePath: path, oldPath: currentOldPath, hunks: hunks))
                }
                // Parse new file path from "diff --git a/path b/path"
                let parts = line.components(separatedBy: " ")
                if parts.count >= 4 {
                    currentFilePath = String(parts.last!.dropFirst(2)) // remove "b/"
                    let aPath = String(parts[2].dropFirst(2)) // remove "a/"
                    currentOldPath = aPath != currentFilePath ? aPath : nil
                }
                currentFileLines = []
            } else {
                currentFileLines.append(line)
            }
        }

        // Flush last file
        if let path = currentFilePath {
            let hunks = parseHunks(from: currentFileLines)
            results.append(DiffResult(filePath: path, oldPath: currentOldPath, hunks: hunks))
        }

        return results
    }

    private static func parseHunks(from lines: [String]) -> [DiffHunk] {
        var hunks: [DiffHunk] = []
        var currentHunkHeader: String?
        var currentHunkLines: [String] = []
        var oldStart = 0, oldCount = 0, newStart = 0, newCount = 0

        for line in lines {
            if line.hasPrefix("@@") {
                // Flush previous hunk
                if let header = currentHunkHeader {
                    let diffLines = parseDiffLines(currentHunkLines, oldStart: oldStart, newStart: newStart)
                    hunks.append(DiffHunk(
                        header: header,
                        oldStart: oldStart, oldCount: oldCount,
                        newStart: newStart, newCount: newCount,
                        lines: diffLines
                    ))
                }

                currentHunkHeader = line
                currentHunkLines = []

                // Parse "@@ -oldStart,oldCount +newStart,newCount @@"
                let pattern = #"@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@"#
                if let match = line.range(of: pattern, options: .regularExpression) {
                    let matchStr = String(line[match])
                    let numbers = matchStr.components(separatedBy: CharacterSet.decimalDigits.inverted)
                        .filter { !$0.isEmpty }
                        .compactMap(Int.init)
                    if numbers.count >= 2 {
                        oldStart = numbers[0]
                        oldCount = numbers.count > 2 ? numbers[1] : 1
                        newStart = numbers.count > 2 ? numbers[2] : numbers[1]
                        newCount = numbers.count > 3 ? numbers[3] : 1
                    }
                }
            } else if currentHunkHeader != nil {
                // Skip file metadata lines (---, +++, index, etc.)
                currentHunkLines.append(line)
            }
        }

        // Flush last hunk
        if let header = currentHunkHeader {
            let diffLines = parseDiffLines(currentHunkLines, oldStart: oldStart, newStart: newStart)
            hunks.append(DiffHunk(
                header: header,
                oldStart: oldStart, oldCount: oldCount,
                newStart: newStart, newCount: newCount,
                lines: diffLines
            ))
        }

        return hunks
    }

    private static func parseDiffLines(_ lines: [String], oldStart: Int, newStart: Int) -> [DiffLine] {
        var result: [DiffLine] = []
        var oldLine = oldStart
        var newLine = newStart

        for line in lines {
            if line.hasPrefix("+") {
                result.append(DiffLine(
                    type: .addition,
                    content: String(line.dropFirst()),
                    oldLineNumber: nil,
                    newLineNumber: newLine
                ))
                newLine += 1
            } else if line.hasPrefix("-") {
                result.append(DiffLine(
                    type: .deletion,
                    content: String(line.dropFirst()),
                    oldLineNumber: oldLine,
                    newLineNumber: nil
                ))
                oldLine += 1
            } else if line.hasPrefix(" ") || line.isEmpty {
                let content = line.isEmpty ? "" : String(line.dropFirst())
                result.append(DiffLine(
                    type: .context,
                    content: content,
                    oldLineNumber: oldLine,
                    newLineNumber: newLine
                ))
                oldLine += 1
                newLine += 1
            }
            // Skip "\ No newline at end of file" and other markers
        }

        return result
    }
}
