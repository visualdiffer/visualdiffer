//
//  FoldersOutlineView+VisibleItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/02/21.
//  Copyright (c) 2021 visualdiffer.com
//

@objc extension FoldersOutlineView {
    func getSelectedVisibleItems(_ includesSelected: Bool) -> [VisibleItem] {
        var arr = [VisibleItem]()

        // At index 0 there is the last selected row
        if selectedRow >= 0 {
            if let vi = item(atRow: selectedRow) as? VisibleItem {
                arr.append(vi)
            }
        }

        if includesSelected {
            for row in selectedRowIndexes where row != selectedRow {
                if let vi = item(atRow: row) as? VisibleItem {
                    arr.append(vi)
                }
            }
        }

        return arr
    }

    @discardableResult
    func select(
        visibleItems items: [VisibleItem],
        scrollToFirst: Bool = false,
        center: Bool = false,
        selectLinked: Bool = false
    ) -> Bool {
        var indexes = IndexSet()

        for vi in items {
            let row = row(forItem: vi)
            if row >= 0 {
                indexes.insert(row)
            }
        }
        if scrollToFirst, let row = indexes.first {
            scrollTo(row: row, center: center)
        }
        selectRowIndexes(indexes, byExtendingSelection: false)
        if selectLinked {
            linkedView?.selectRowIndexes(indexes, byExtendingSelection: false)
        }
        return !indexes.isEmpty
    }

    func restoreSelectionAndFocusPosition(_ selectedVisibleItems: [VisibleItem]) {
        if selectedVisibleItems.isEmpty {
            return
        }
        var indexes = IndexSet()
        let focusVI = selectedVisibleItems[0]

        // start from 1 to skip focus item
        for vi in selectedVisibleItems.dropFirst() {
            let row = row(forItem: vi)
            if row >= 0 {
                indexes.insert(row)
            }
        }

        let focusItem = focusVI.item
        var focusRow = row(forItem: focusVI)

        if focusRow < 0 {
            let count = numberOfRows
            for row in 0 ..< count {
                guard let vi = item(atRow: row) as? VisibleItem else {
                    continue
                }
                let res = URL.compare(path: vi.item.toUrl(), with: focusItem.toUrl())

                if res == .orderedSame || res == .orderedDescending {
                    focusRow = row
                    if res == .orderedDescending, row > 0 {
                        focusRow -= 1
                    }
                    indexes.insert(focusRow)
                    break
                }
            }
        } else {
            indexes.insert(focusRow)
        }

        scrollRowToVisible(focusRow)
        selectRowIndexes(indexes, byExtendingSelection: false)
        linkedView?.selectRowIndexes(indexes, byExtendingSelection: false)
    }

    func expandParents(of child: VisibleItem) {
        var parents = [VisibleItem]()

        var parent = child.item.parent

        while parent?.parent != nil {
            if let vi = parent?.visibleItem {
                parents.append(vi)
            }
            parent = parent?.parent
        }

        for parent in parents.reversed() {
            expandItem(parent)
        }
    }
}
