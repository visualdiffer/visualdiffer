//
//  VisibleItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

public class VisibleItem: NSObject {
    var item: CompareItem
    var linkedItem: VisibleItem?
    private(set) var children: [VisibleItem] = []

    private init(_ item: CompareItem) {
        self.item = item

        super.init()

        self.item.visibleItem = self
    }

    static func createLinked(_ item: CompareItem) -> VisibleItem {
        guard let linkedItem = item.linkedItem else {
            fatalError("Linked item must be set")
        }

        let vi = VisibleItem(item)
        let linkedVI = VisibleItem(linkedItem)

        vi.linkedItem = linkedVI
        linkedVI.linkedItem = vi

        return vi
    }

    func add(_ vi: VisibleItem) {
        children.append(vi)
    }

    func remove(_ vi: VisibleItem) {
        let index = children.firstIndex(of: vi)
        if let index {
            children.remove(at: index)
        }
    }

    func removeAll() {
        children.removeAll()
    }

    func swap() {
        guard let linkedItem else {
            return
        }
        let tempItem = item
        item = linkedItem.item
        linkedItem.item = tempItem

        for vi in children {
            vi.swap()
        }
    }

    var childrenAllFiltered: Bool {
        if item.isFolder {
            for vi in children where !vi.item.isFiltered {
                return false
            }
            return true
        }
        return false
    }

    /**
     If the file object is invalid the linkedItem is passed,
     this ensure the comparator receives always two valid file object
     */
    func sortChildren(
        _ ascending: Bool,
        ignoreCase: Bool,
        comparator: (CompareItem, CompareItem) -> ComparisonResult
    ) {
        for vi in children where vi.item.isFolder {
            vi.sortChildren(ascending, ignoreCase: ignoreCase, comparator: comparator)
        }
        children.sort { (lhs: VisibleItem, rhs: VisibleItem) -> Bool in
            guard let fs1 = lhs.item.isValidFile ? lhs.item : lhs.item.linkedItem,
                  let fs2 = rhs.item.isValidFile ? rhs.item : rhs.item.linkedItem else {
                return false
            }

            let isFile1 = fs1.isFile
            let isFile2 = fs2.isFile
            let isFolder1 = fs1.isFolder
            let isFolder2 = fs2.isFolder
            // check if invalid files have path otherwise isn't necessary to compare
            let bothInvalidWithPath = !fs1.isValidFile && !fs2.isValidFile && (fs1.path != nil || fs2.path != nil)

            if isFolder1 && isFolder2 || (isFile1 && isFile2) || bothInvalidWithPath {
                var result = comparator(fs1, fs2)

                if result == .orderedSame {
                    // swiftlint:disable force_unwrapping
                    result = ignoreCase
                        ? fs1.fileName!.localizedCaseInsensitiveCompare(fs2.fileName!)
                        : fs1.fileName!.localizedCompare(fs2.fileName!)
                    // swiftlint:enable force_unwrapping
                }
                if !ascending, result != .orderedSame {
                    result = result == .orderedAscending ? .orderedDescending : .orderedAscending
                }
                return result == .orderedAscending
            }
            // Place directories before files
            return isFolder1
        }
        for (index, vi) in children.enumerated() {
            guard let li = vi.linkedItem else {
                fatalError("LinkedItem must be set for all visible items")
            }
            linkedItem?.children[index] = li
        }
    }
}
