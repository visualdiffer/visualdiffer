//
//  DescriptionOutlineNode.swift
//  VisualDiffer
//
//  Created by davide ficano on 02/02/12.
//  Copyright (c) 2012 visualdiffer.com
//

class DescriptionOutlineNode: NSObject {
    let text: String
    let isContainer: Bool
    var children: [DescriptionOutlineNode]
    var items: [CompareItem]?

    init(text: String, isContainer: Bool = false) {
        self.text = text
        self.isContainer = isContainer
        children = []
    }

    convenience init(
        relativePath text: String,
        items: [CompareItem],
        rootPath: String
    ) {
        self.init(text: text, isContainer: true)

        self.items = items
        let rootPathLen = rootPath.standardizingPath.count + 1

        for item in items {
            guard let path = item.path else {
                continue
            }
            let start = path.index(path.startIndex, offsetBy: rootPathLen)
            let relativePath = String(path[start ..< path.endIndex])
            let node = DescriptionOutlineNode(text: relativePath)
            children.append(node)
        }
    }
}
