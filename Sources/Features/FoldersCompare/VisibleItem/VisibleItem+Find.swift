//
//  VisibleItem+Find.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

struct FileNameFilter {
    let matches: (String) -> Bool
    let includesFiles: Bool
    let includesFolders: Bool
}

extension VisibleItem {
    func findItems(matching filter: FileNameFilter) -> [VisibleItem] {
        var foundItems = [VisibleItem]()
        findItems(matching: filter, into: &foundItems)
        return foundItems
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
        matching filter: FileNameFilter,
        into foundItems: inout [VisibleItem]
    ) {
        guard let fileName = item.fileName ?? item.linkedItem?.fileName else {
            return
        }

        let isIncluded = item.isFolder ? filter.includesFolders : filter.includesFiles

        if isIncluded, filter.matches(fileName) {
            foundItems.append(self)
        }

        // the children are always visited, a folder excluded from the search can contain matching files
        for vi in children {
            vi.findItems(matching: filter, into: &foundItems)
        }
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
