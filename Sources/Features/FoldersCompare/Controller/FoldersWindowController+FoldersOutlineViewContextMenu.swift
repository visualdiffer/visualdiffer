//
//  FoldersWindowController+FoldersOutlineViewContextMenu.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController: FoldersOutlineViewContextMenu {
    @objc func compareFiles(_: AnyObject?) {
        let leftSelItems = leftView.selectedItems()
        let rightSelItems = rightView.selectedItems()
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
            leftItem = rightSelItems[0]
            rightItem = rightSelItems[1]
        default:
            return
        }
        do {
            _ = try VDDocumentController.shared.openDifferDocument(
                leftUrl: leftItem?.toUrl(),
                rightUrl: rightItem?.toUrl()
            )
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    @objc func compareFolders(_ sender: AnyObject?) {
        compareFiles(sender)
    }

    @objc func copyFileNames(_: AnyObject?) {
        lastUsedView.copySelectedAsFileNames()
    }

    @objc func copy(_ sender: AnyObject?) {
        copyFullPaths(sender)
    }

    @objc func copyFullPaths(_: AnyObject?) {
        lastUsedView.copySelectedAsFullPaths()
    }

    @objc func expandSelectedSubfolders(_: AnyObject?) {
        lastUsedView.expandSelectedSubfolders()

        // expand also selected rows on linkedView that may be different for those selected on this view
        lastUsedView.linkedView?.expandSelectedSubfolders()
    }

    @objc func popupOpenWithApp(_: AnyObject?) {
        // Make Cocoa happy otherwise without action the menuitem is always grayed
    }

    @objc func showInFinder(_: AnyObject?) {
        lastUsedView.showSelectedInFinder()
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
