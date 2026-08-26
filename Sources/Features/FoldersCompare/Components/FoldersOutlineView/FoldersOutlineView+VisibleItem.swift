//
//  FoldersOutlineView+VisibleItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/02/21.
//  Copyright (c) 2021 visualdiffer.com
//

extension FoldersOutlineView {
    func getSelectedVisibleItems(_ includesSelected: Bool) -> [VisibleItem] {
        var arr = [VisibleItem]()

        // at index 0 there is the last selected row
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

    func rows(forItems items: [VisibleItem]) -> IndexSet {
        var indexes = IndexSet()

        for vi in items {
            let row = row(forItem: vi)
            if row >= 0 {
                indexes.insert(row)
            }
        }

        return indexes
    }

    @discardableResult
    func select(
        visibleItems items: [VisibleItem],
        scrollToFirst: Bool = false,
        center: Bool = false,
        selectLinked: Bool = false,
        byExtendingSelection: Bool = false
    ) -> Bool {
        select(
            rows: rows(forItems: items),
            scrollToFirst: scrollToFirst,
            center: center,
            selectLinked: selectLinked,
            byExtendingSelection: byExtendingSelection
        )
    }

    @discardableResult
    func select(
        rows: IndexSet,
        scrollToFirst: Bool = false,
        center: Bool = false,
        selectLinked: Bool = false,
        byExtendingSelection: Bool = false
    ) -> Bool {
        if scrollToFirst, let row = rows.first {
            scrollTo(row: row, center: center)
        }
        selectRowIndexes(rows, byExtendingSelection: byExtendingSelection)
        if selectLinked {
            linkedView?.selectRowIndexes(rows, byExtendingSelection: byExtendingSelection)
        }
        return !rows.isEmpty
    }

    func restoreSelectionAndFocusPosition(_ selectedVisibleItems: [VisibleItem]) {
        let paths = selectedVisibleItems.compactMap { $0.item.path ?? $0.item.linkedItem?.path }
        guard !paths.isEmpty else {
            return
        }

        var (indexes, focusRow) = indexSet(forPaths: paths)

        if focusRow < 0 {
            focusRow = findNearest(to: URL(filePath: paths[0]))
            if focusRow >= 0 {
                indexes.insert(focusRow)
            }
        }

        guard !indexes.isEmpty else {
            return
        }

        select(rows: indexes, selectLinked: true)
        scrollTo(row: focusRow, center: true)
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

        for parent in parents.reversed() where !isItemExpanded(parent) {
            expandItem(parent)
        }
    }

    func expandedFolderPaths() -> Set<String> {
        var paths = Set<String>()

        for row in 0 ..< numberOfRows {
            guard let folder = item(atRow: row) as? VisibleItem,
                  folder.item.isFolder,
                  isItemExpanded(folder),
                  let path = folder.item.path ?? folder.item.linkedItem?.path else {
                continue
            }

            paths.insert(path)
        }

        return paths
    }

    func expandFolders(with paths: Set<String>, from folder: VisibleItem? = nil) {
        if paths.isEmpty {
            return
        }

        if let folder {
            expandFolders(with: paths, folder: folder)
            return
        }

        guard let dataSource else {
            return
        }

        let count = dataSource.outlineView?(self, numberOfChildrenOfItem: nil) ?? 0

        for index in 0 ..< count {
            guard let folder = dataSource.outlineView?(self, child: index, ofItem: nil) as? VisibleItem else {
                continue
            }

            expandFolders(with: paths, folder: folder)
        }
    }

    private func expandFolders(with paths: Set<String>, folder: VisibleItem) {
        if folder.item.isFolder,
           let path = folder.item.path ?? folder.item.linkedItem?.path,
           paths.contains(path),
           row(forItem: folder) >= 0 {
            expandItem(folder)
        }

        for child in folder.children {
            expandFolders(with: paths, folder: child)
        }
    }

    func restoreSelection(paths: [String]) {
        guard !paths.isEmpty else {
            return
        }

        let (indexes, focusRow) = indexSet(forPaths: paths)
        guard !indexes.isEmpty else {
            return
        }

        select(rows: indexes)
        scrollTo(row: focusRow, center: true)
    }

    private func indexSet(
        forPaths paths: [String]
    ) -> (indexes: IndexSet, focusRow: Int) {
        let focusPath = paths[0]
        var indexes = IndexSet()
        var focusRow = -1

        for row in 0 ..< numberOfRows {
            guard let vi = item(atRow: row) as? VisibleItem,
                  let viPath = vi.item.path ?? vi.item.linkedItem?.path,
                  paths.contains(viPath) else {
                continue
            }

            indexes.insert(row)
            if viPath == focusPath {
                focusRow = row
            }
        }

        return (indexes, focusRow)
    }

    func findNearest(to url: URL) -> Int {
        for row in 0 ..< numberOfRows {
            guard let vi = item(atRow: row) as? VisibleItem else {
                continue
            }

            let res = URL.compare(path: vi.item.toURL(), with: url)
            if res == .orderedSame || res == .orderedDescending {
                return res == .orderedDescending && row > 0 ? row - 1 : row
            }
        }

        return -1
    }

    func captureSelectionForRestore(preserveExistingWhenEmpty: Bool) {
        let selectedPaths = getSelectedVisibleItems(true).compactMap {
            $0.item.path ?? $0.item.linkedItem?.path
        }
        if preserveExistingWhenEmpty, selectedPaths.isEmpty {
            return
        }
        selectionRestorePaths = selectedPaths
    }

    func restoreCapturedSelection() {
        restoreSelection(paths: selectionRestorePaths)
    }
}
