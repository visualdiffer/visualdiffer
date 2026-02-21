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
    @objc
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

    func isAncestor(of child: CompareItem) -> Bool {
        guard let parentUrl = toUrl(),
              let childUrl = child.toUrl() else {
            return false
        }

        // pathComponents returns leading "/" and any extra trailing "/"
        // e.g. /a//b/c/// returns ["/", "a", "b", "c", "/"] so we filter out any "/" manually
        let parentComponents = parentUrl.pathComponents.filter { $0 != "/" }
        let childComponents = childUrl.pathComponents.filter { $0 != "/" }

        return childComponents.starts(with: parentComponents)
    }
}
