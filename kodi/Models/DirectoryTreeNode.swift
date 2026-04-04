import Foundation

struct DirectoryTreeNode: Identifiable {
    let id: String
    let name: String
    var children: [DirectoryTreeNode]
    let isFolder: Bool

    var fileCount: Int {
        if !isFolder { return 1 }
        return children.reduce(0) { $0 + $1.fileCount }
    }

    // MARK: - Tree Building

    static func buildTree(from paths: [String]) -> [DirectoryTreeNode] {
        var nodes = buildLevel(paths: paths, depth: 0, pathPrefix: "")
        nodes = collapseChains(nodes)
        while nodes.count == 1 && nodes[0].isFolder {
            nodes = nodes[0].children
        }
        return nodes
    }

    private static func buildLevel(paths: [String], depth: Int, pathPrefix: String) -> [DirectoryTreeNode] {
        var folderGroups: [String: [String]] = [:]
        var leafFiles: [String] = []

        for path in paths {
            let components = path.split(separator: "/").map(String.init)
            if depth < components.count - 1 {
                let folderName = components[depth]
                folderGroups[folderName, default: []].append(path)
            } else if depth < components.count {
                leafFiles.append(path)
            }
        }

        var nodes: [DirectoryTreeNode] = []

        for name in folderGroups.keys.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }) {
            let folderPath = pathPrefix.isEmpty ? name : pathPrefix + "/" + name
            let children = buildLevel(paths: folderGroups[name]!, depth: depth + 1, pathPrefix: folderPath)
            nodes.append(DirectoryTreeNode(id: folderPath, name: name, children: children, isFolder: true))
        }

        for path in leafFiles.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }) {
            let fileName = URL(fileURLWithPath: path).lastPathComponent
            nodes.append(DirectoryTreeNode(id: path, name: fileName, children: [], isFolder: false))
        }

        return nodes
    }

    // MARK: - Chain Collapsing

    private static func collapseChains(_ nodes: [DirectoryTreeNode]) -> [DirectoryTreeNode] {
        nodes.map { node in
            var current = node
            while current.isFolder && current.children.count == 1 && current.children[0].isFolder {
                let child = current.children[0]
                current = DirectoryTreeNode(
                    id: child.id,
                    name: current.name + "/" + child.name,
                    children: child.children,
                    isFolder: true
                )
            }
            current.children = collapseChains(current.children)
            return current
        }
    }
}
