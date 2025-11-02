//
//  FoldersWindowController+Document.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

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

    public func nextDifferenceFiles(from leftPath: String?, rightPath: String?, block: DiffOpenerDelegateBlock) {
        findDifference(from: leftPath, rightPath: rightPath, findNext: true, block: block)
    }

    public func prevDifferenceFiles(from leftPath: String?, rightPath: String?, block: DiffOpenerDelegateBlock) {
        findDifference(from: leftPath, rightPath: rightPath, findNext: false, block: block)
    }

    func findDifference(from leftPath: String?, rightPath: String?, findNext: Bool, block: DiffOpenerDelegateBlock) {
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

        var foundItem: (CompareItem, Int)?

        if let item, let parent = item.parent, parent.visibleItem != nil, let vi = item.visibleItem {
            foundItem = findNearest(
                vi,
                parentPath: parent.path,
                direction: findNext ? 1 : -1,
                limitToCurrentFolder: false
            )
        }

        if let (item, row) = foundItem, block(item.path, item.linkedItem?.path) {
            leftView.scrollRowToVisible(row)
            let indexes = IndexSet(integer: row)
            leftView.selectRowIndexes(indexes, byExtendingSelection: false)
            leftView.linkedView?.selectRowIndexes(indexes, byExtendingSelection: false)
        }
    }

    private func findNearest(
        _ vi: VisibleItem,
        parentPath: String?,
        direction: Int,
        limitToCurrentFolder: Bool
    ) -> (CompareItem, Int)? {
        var row = leftView.row(forItem: vi)

        if row < 0 {
            return nil
        }
        while true {
            row += direction
            guard let vi = leftView.item(atRow: row) as? VisibleItem else {
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
}
