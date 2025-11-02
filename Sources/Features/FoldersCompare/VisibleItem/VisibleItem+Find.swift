//
//  VisibleItem+Find.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension VisibleItem {
    func findFileName(
        regex: NSRegularExpression,
        searchFullPath usePath: Bool,
        items: inout [VisibleItem]
    ) {
        let fileName = if usePath {
            item.path ?? item.linkedItem?.path
        } else {
            item.fileName ?? item.linkedItem?.fileName
        }
        guard let fileName else {
            return
        }
        if regex.firstMatch(
            in: fileName,
            options: [],
            range: NSRange(location: 0, length: fileName.count)
        ) != nil {
            items.append(self)
        }

        for vi in children {
            vi.findFileName(regex: regex, searchFullPath: usePath, items: &items)
        }
    }
}
