import Foundation

struct FileTreeNode: Identifiable {
    let id: String
    let name: String
    var children: [FileTreeNode]
    let file: ChangedFile?

    var isFolder: Bool { file == nil }

    var fileCount: Int {
        if !isFolder { return 1 }
        return children.reduce(0) { $0 + $1.fileCount }
    }

    /// All ChangedFile instances contained in this node (recursively)
    var allFiles: [ChangedFile] {
        if let file { return [file] }
        return children.flatMap(\.allFiles)
    }

    // MARK: - Tree Building

    static func buildTree(from files: [ChangedFile]) -> [FileTreeNode] {
        var nodes = buildLevel(files: files, depth: 0, pathPrefix: "")
        nodes = collapseChains(nodes)
        // Strip root folder if there's a single root folder containing everything
        while nodes.count == 1 && nodes[0].isFolder {
            nodes = nodes[0].children
        }
        return nodes
    }

    private static func buildLevel(files: [ChangedFile], depth: Int, pathPrefix: String) -> [FileTreeNode] {
        var folderGroups: [String: [ChangedFile]] = [:]
        var leafFiles: [ChangedFile] = []

        for file in files {
            let components = file.path.split(separator: "/").map(String.init)
            if depth < components.count - 1 {
                let folderName = components[depth]
                folderGroups[folderName, default: []].append(file)
            } else {
                leafFiles.append(file)
            }
        }

        var nodes: [FileTreeNode] = []

        // Folders first, sorted alphabetically
        for name in folderGroups.keys.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }) {
            let folderPath = pathPrefix.isEmpty ? name : pathPrefix + "/" + name
            let children = buildLevel(files: folderGroups[name]!, depth: depth + 1, pathPrefix: folderPath)
            nodes.append(FileTreeNode(id: folderPath, name: name, children: children, file: nil))
        }

        // Files after folders, sorted alphabetically
        for file in leafFiles.sorted(by: { $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending }) {
            nodes.append(FileTreeNode(id: file.path, name: file.fileName, children: [], file: file))
        }

        return nodes
    }

    // MARK: - Chain Collapsing

    /// Collapses single-child folder chains: src/ > components/ becomes src/components/
    private static func collapseChains(_ nodes: [FileTreeNode]) -> [FileTreeNode] {
        nodes.map { node in
            var current = node
            while current.isFolder && current.children.count == 1 && current.children[0].isFolder {
                let child = current.children[0]
                current = FileTreeNode(
                    id: child.id,
                    name: current.name + "/" + child.name,
                    children: child.children,
                    file: nil
                )
            }
            current.children = collapseChains(current.children)
            return current
        }
    }
}
