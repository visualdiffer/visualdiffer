//
//  FoldersWindowController+FoldersOutlineViewContextMenu.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController: FoldersOutlineViewContextMenu {
    @objc
    func compareItems(_: AnyObject?) {
        let leftSelItems = leftView.selectedItems(findLeafPaths: false)
        let rightSelItems = rightView.selectedItems(findLeafPaths: false)
        var leftItem: CompareItem?
        var rightItem: CompareItem?

        switch leftSelItems.count {
        case 2:
            leftItem = leftSelItems[0]
            rightItem = leftSelItems[1]
        case 1:
            leftItem = leftSelItems.last
            rightItem = rightSelItems.last
        case 0:
            guard rightSelItems.count == 2 else {
                return
            }

            leftItem = rightSelItems[0]
            rightItem = rightSelItems[1]
        default:
            return
        }
        do {
            _ = try VDDocumentController.shared.openDifferDocument(
                leftURL: leftItem?.toURL(),
                rightURL: rightItem?.toURL()
            )
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    @objc
    func copyFileNames(_: AnyObject?) {
        lastUsedView.copySelectedAsFileNames()
    }

    @objc
    func copy(_ sender: AnyObject?) {
        copyFullPaths(sender)
    }

    @objc
    func copyFullPaths(_: AnyObject?) {
        lastUsedView.copySelectedAsFullPaths()
    }

    @objc
    func expandSelectedSubfolders(_: AnyObject?) {
        lastUsedView.expandSelectedSubfolders()

        // expand also selected rows on linkedView that may be different for those selected on this view
        lastUsedView.linkedView?.expandSelectedSubfolders()
    }

    @objc
    func popupOpenWithApp(_: AnyObject?) {
        // Make Cocoa happy otherwise without action the menuitem is always grayed
    }

    @objc
    func showInFinder(_: AnyObject?) {
        lastUsedView.showSelectedInFinder()
    }

    @objc
    func selectAllFilesInSelection(_: AnyObject?) {
        selectInSelection { $0.findFiles() }
    }

    @objc
    func selectAllFoldersInSelection(_: AnyObject?) {
        selectInSelection { $0.findFolders() }
    }

    @objc
    func selectNewerInSelection(_: AnyObject?) {
        selectInSelection { $0.findFiles(ofType: .changed) }
    }

    @objc
    func selectOrphansInSelection(_: AnyObject?) {
        selectInSelection { $0.findFiles(ofType: .orphan) }
    }

    private func selectInSelection(
        matching: (VisibleItem) -> [VisibleItem]
    ) {
        let items = lastUsedView.selectedItems(findLeafPaths: false)
            .compactMap(\.visibleItem)
            .flatMap(matching)

        lastUsedView.select(visibleItems: items)
    }
}

extension FoldersOutlineView {
    func expandSelectedSubfolders() {
        for row in selectedRowIndexes.reversed() {
            let item = item(atRow: row)
            expandItem(item, expandChildren: true)
        }
    }
}
