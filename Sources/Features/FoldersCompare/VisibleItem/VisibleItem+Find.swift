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
            range: NSRange(location: 0, length: fileName.utf16.count)
        ) != nil {
            items.append(self)
        }

        for vi in children {
            vi.findFileName(regex: regex, searchFullPath: usePath, items: &items)
        }
    }

    func findItems(_ isIncluded: (VisibleItem) -> Bool) -> [VisibleItem] {
        var foundItems = [VisibleItem]()
        findItems(isIncluded, into: &foundItems)
        return foundItems
    }

    func findFiles(ofType type: CompareChangeType) -> [VisibleItem] {
        findItems { $0.item.isFile && $0.item.type == type }
    }

    func findFiles() -> [VisibleItem] {
        findItems { $0.item.isFile }
    }

    func findFolders() -> [VisibleItem] {
        findItems { $0.item.isFolder }
    }

    private func findItems(
        _ isIncluded: (VisibleItem) -> Bool,
        into foundItems: inout [VisibleItem]
    ) {
        for vi in children where vi.item.isValidFile {
            if isIncluded(vi) {
                foundItems.append(vi)
            }
            if vi.item.isFolder {
                vi.findItems(isIncluded, into: &foundItems)
            }
        }
    }
}
