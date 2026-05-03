//
//  FoldersWindowController+Document.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

enum NavigationDirection {
    case previous
    case next

    func sign() -> Int {
        self == .previous ? -1 : 1
    }
}

extension FoldersWindowController: DiffOpenerDelegate {
    override open var document: AnyObject? {
        didSet {
            // create a shortcut to sessionDiff held by document
            if let sessionDiff = (document as? VDDocument)?.sessionDiff {
                self.sessionDiff = sessionDiff
                setupUIState()
            }
        }
    }

    public func addChildDocument(_ document: VDDocument) {
        sessionChildren.append(document)
        document.parentSession = self
    }

    public func removeChildDocument(_ document: VDDocument) {
        let index = sessionChildren.firstIndex { $0 === document }
        if let index {
            sessionChildren.remove(at: index)
            document.parentSession = nil
        }
    }

    func removeAllChildrenDocuments() {
        for document in sessionChildren {
            document.parentSession = nil
        }
        sessionChildren.removeAll()
    }

    public func openNextDifference(from leftPath: String?, rightPath: String?, block: DiffOpenerDelegateBlock) {
        findDifference(from: leftPath, rightPath: rightPath, direction: .next, block: block)
    }

    public func openPreviousDifference(from leftPath: String?, rightPath: String?, block: DiffOpenerDelegateBlock) {
        findDifference(from: leftPath, rightPath: rightPath, direction: .previous, block: block)
    }

    public func hasNextDifference(from leftPath: String?, rightPath: String?) -> Bool {
        findNearestDifferenceItem(from: leftPath, rightPath: rightPath, direction: .next) != nil
    }

    public func hasPreviousDifference(from leftPath: String?, rightPath: String?) -> Bool {
        findNearestDifferenceItem(from: leftPath, rightPath: rightPath, direction: .previous) != nil
    }

    public func parentPaths(from leftPath: String?, rightPath: String?) -> (leftParentPath: String, rightParentPath: String)? {
        guard let item = resolveCompareItem(fromLeftPath: leftPath, rightPath: rightPath),
              let leftParent = item.parent?.path,
              let rightParent = item.linkedItem?.parent?.path else {
            return nil
        }

        return (leftParent, rightParent)
    }

    /// resolves the compare item associated with one of the provided paths
    /// - parameters:
    ///   - leftPath: the candidate path to resolve from the left or right session root
    ///   - rightPath: the fallback path to resolve when `leftPath` is missing or empty
    /// - returns: the matching compare item from the left comparison tree, even when the resolved path originates from the right side
    public func resolveCompareItem(
        fromLeftPath leftPath: String?,
        rightPath: String?
    ) -> CompareItem? {
        var item: CompareItem?

        if let leftPath, !leftPath.isEmpty {
            if let leftItemOriginal,
               let leftSessionPath = sessionDiff.leftPath,
               leftPath.hasPrefix(leftSessionPath) {
                item = CompareItem.find(withPath: leftPath, from: leftItemOriginal)
            } else if let rightItemOriginal,
                      let rightSessionPath = sessionDiff.rightPath,
                      leftPath.hasPrefix(rightSessionPath) {
                item = CompareItem.find(withPath: leftPath, from: rightItemOriginal)?.linkedItem
            }
        } else if let rightPath, !rightPath.isEmpty {
            if let leftItemOriginal,
               let leftSessionPath = sessionDiff.leftPath,
               rightPath.hasPrefix(leftSessionPath) {
                item = CompareItem.find(withPath: rightPath, from: leftItemOriginal)
            } else if let rightItemOriginal,
                      let rightSessionPath = sessionDiff.rightPath,
                      rightPath.hasPrefix(rightSessionPath) {
                item = CompareItem.find(withPath: rightPath, from: rightItemOriginal)?.linkedItem
            }
        }

        return item
    }

    private func findNearestDifferenceItem(
        from leftPath: String?,
        rightPath: String?,
        direction: NavigationDirection
    ) -> (item: CompareItem, row: Int)? {
        guard let item = resolveCompareItem(fromLeftPath: leftPath, rightPath: rightPath),
              let vi = item.visibleItem else {
            return nil
        }

        return findNearest(
            view: leftView,
            item: vi,
            parentPath: item.parent?.path,
            direction: direction,
            limitToCurrentFolder: false
        )
    }

    private func findDifference(
        from leftPath: String?,
        rightPath: String?,
        direction: NavigationDirection,
        block: DiffOpenerDelegateBlock
    ) {
        let foundItem = findNearestDifferenceItem(
            from: leftPath,
            rightPath: rightPath,
            direction: direction
        )

        if let (item, row) = foundItem, block(item.path, item.linkedItem?.path) {
            leftView.select(
                rows: IndexSet(integer: row),
                scrollToFirst: true,
                center: true,
                selectLinked: true
            )
        }
    }

    func findNearest(
        view: FoldersOutlineView,
        item vi: VisibleItem,
        parentPath: String?,
        direction: NavigationDirection,
        limitToCurrentFolder: Bool
    ) -> (item: CompareItem, row: Int)? {
        var row = view.row(forItem: vi)

        if row < 0 {
            row = anchorRowForFilteredItem(view: view, item: vi, direction: direction)
        }

        let rowDirection = direction.sign()

        while true {
            row += rowDirection
            guard let vi = view.item(atRow: row) as? VisibleItem else {
                break
            }

            let fs1 = vi.item
            if limitToCurrentFolder, fs1.isFolder, fs1.path != parentPath {
                break
            }
            if fs1.isFile, fs1.type != .same {
                return (fs1, row)
            }
        }
        return nil
    }

    // finds the outline row to use as loop start when vi has been filtered out;
    // walks up the ancestor chain in case the parent itself was also removed
    private func anchorRowForFilteredItem(
        view: FoldersOutlineView,
        item vi: VisibleItem,
        direction: NavigationDirection
    ) -> Int {
        var currentItem = vi.item

        while let parent = currentItem.parent {
            let siblings = parent.children
            if let index = siblings.firstIndex(of: currentItem) {
                var pos = index + 1
                while pos < siblings.count {
                    if siblings[pos].isDisplayed {
                        break
                    }
                    pos += 1
                }
                // for "next": start just before nextRow so the loop lands on it
                // for "prev": start at nextRow so the loop checks the row before it first
                if pos < siblings.count, let nextVI = siblings[pos].visibleItem {
                    let nextRow = view.row(forItem: nextVI)
                    if nextRow >= 0 {
                        return direction == .next ? nextRow - 1 : nextRow
                    }
                }
                // no visible next sibling — derive anchor from end of parent's visible subtree
                if let parentVI = parent.visibleItem {
                    let lastRow = lastVisibleRow(in: parentVI, view: view)
                    if lastRow >= 0 {
                        let nextRow = lastRow + 1
                        return direction == .next ? nextRow - 1 : nextRow
                    }
                }
            }
            currentItem = parent
        }

        return -1
    }

    private func lastVisibleRow(in vi: VisibleItem, view: FoldersOutlineView) -> Int {
        for child in vi.children.reversed() {
            let row = lastVisibleRow(in: child, view: view)
            if row >= 0 {
                return row
            }
        }
        return view.row(forItem: vi)
    }
}
