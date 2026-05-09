//
//  CompareItem+LeafPath.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension CompareItem {
    /**
     * Eliminate all ancestor elements from the provided array.
     * The resulting array will contain only leaf paths.
     */
    static func findLeafPaths(_ items: [CompareItem]) -> [CompareItem] {
        // The items must be sorted to find correctly the leaves
        let arr = items.sorted {
            let lhs = $0.path ?? ""
            let rhs = $1.path ?? ""
            return lhs.localizedCompare(rhs) == .orderedAscending
        }

        var leaves = [CompareItem]()

        for (i, item) in arr.enumerated() {
            var isLeaf = true

            if (i + 1) < arr.count {
                if item.isAncestor(of: arr[i + 1]) {
                    isLeaf = false
                }
            }
            if isLeaf {
                leaves.append(item)
            }
        }

        return leaves
    }

    /// Returns the common ancestor path shared by all items' parent directories.
    ///
    /// For example, given items with parents `/l/dir/deeper` and `/l/dir/level2`,
    /// returns `/l/dir`.
    ///
    /// - Parameter items: The items whose parent paths are compared.
    /// - Returns: The longest common ancestor path, or `nil` if any item has no parent
    ///   or the items list is empty.
    static func commonAncestorPath(_ items: [CompareItem]) -> String? {
        let parentURLs = items.compactMap { $0.parent?.toURL() }

        guard parentURLs.count == items.count,
              let first = parentURLs.first else {
            return nil
        }

        let firstComponents = first.pathComponents
        var commonCount = firstComponents.count

        for parentURL in parentURLs.dropFirst() {
            let components = parentURL.pathComponents
            let maxCount = min(commonCount, components.count)
            var index = 0

            while index < maxCount, firstComponents[index] == components[index] {
                index += 1
            }

            guard index > 0 else {
                return nil
            }

            commonCount = index
        }

        return pathFromComponents(Array(firstComponents.prefix(commonCount)))
    }

    private static func pathFromComponents(_ components: [String]) -> String? {
        guard let first = components.first else {
            return nil
        }

        let rest = components.dropFirst()

        if first == "/" {
            return "/" + rest.joined(separator: "/")
        }

        return rest.isEmpty ? first : components.joined(separator: "/")
    }

    func isAncestor(of child: CompareItem) -> Bool {
        guard let parentURL = toURL(),
              let childURL = child.toURL() else {
            return false
        }

        // pathComponents returns leading "/" and any extra trailing "/"
        // e.g. /a//b/c/// returns ["/", "a", "b", "c", "/"] so we filter out any "/" manually
        let parentComponents = parentURL.pathComponents.filter { $0 != "/" }
        let childComponents = childURL.pathComponents.filter { $0 != "/" }

        return childComponents.starts(with: parentComponents)
    }
}
