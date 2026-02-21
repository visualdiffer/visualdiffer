//
//  FoldersWindowController+BaseFolder.swift
//  VisualDiffer
//
//  Created by davide ficano on 20/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController {
    @objc
    func setAsBaseFolder(_ sender: AnyObject?) {
        if let sender = sender as? NSMenuItem,
           isPathControlMenu(sender.tag) {
            let leftUrl = leftPanelView.pathView.pathControl.clickedPath
            var leftPath: String?
            var rightPath: String?

            if let leftUrl {
                leftPath = leftUrl.osPath
                rightPath = leftVisibleItems?.item.linkedItem?.path
            } else {
                leftPath = leftVisibleItems?.item.path
                rightPath = rightPanelView.pathView.pathControl.clickedPath?.osPath
            }
            setBaseFolders(leftPath, rightPath: rightPath)
            return
        }

        let row = lastUsedView.selectedRow

        if row < 0 {
            return
        }
        var leftItem: CompareItem?
        var rightItem: CompareItem?
        if lastUsedView.side == .left {
            if let vi = lastUsedView.item(atRow: row) as? VisibleItem {
                let item = vi.item
                leftItem = item
                rightItem = rightItemOriginal
            }
        } else {
            if let vi = lastUsedView.item(atRow: row) as? VisibleItem {
                let item = vi.item
                leftItem = leftItemOriginal
                rightItem = item
            }
        }
        setBaseFolders(leftItem, right: rightItem)
    }

    @objc
    func setAsBaseFoldersBothSides(_: AnyObject?) {
        var leftItem: CompareItem?
        var rightItem: CompareItem?
        let indexes = lastUsedView.selectedRowIndexes

        if indexes.count == 2 {
            if let first = indexes.first,
               let vi = lastUsedView.item(atRow: first) as? VisibleItem {
                leftItem = vi.item
            }
            if let last = indexes.last,
               let vi = lastUsedView.item(atRow: last) as? VisibleItem {
                rightItem = vi.item
            }
        } else {
            let baseView = if lastUsedView.side == .left {
                lastUsedView
            } else {
                lastUsedView.linkedView
            }

            if let baseView {
                if let vi = baseView.item(atRow: baseView.selectedRow) as? VisibleItem {
                    leftItem = vi.item
                }
                if let linkedView = baseView.linkedView,
                   let vi = linkedView.item(atRow: linkedView.selectedRow) as? VisibleItem {
                    rightItem = vi.item
                }
            }
        }
        setBaseFolders(leftItem, right: rightItem)
    }

    @objc
    func setAsBaseFolderOtherSide(_ sender: AnyObject?) {
        if let sender = sender as? NSMenuItem,
           isPathControlMenu(sender.tag) {
            let leftUrl = leftPanelView.pathView.pathControl.clickedPath
            var leftPath: String?
            var rightPath: String?

            if let leftUrl {
                leftPath = leftVisibleItems?.item.path
                rightPath = leftUrl.osPath
            } else {
                leftPath = rightPanelView.pathView.pathControl.clickedPath?.osPath
                rightPath = leftVisibleItems?.item.linkedItem?.path
            }
            setBaseFolders(leftPath, rightPath: rightPath)
            return
        }

        let row = lastUsedView.selectedRow

        if row < 0 {
            return
        }
        var leftItem: CompareItem?
        var rightItem: CompareItem?
        if lastUsedView.side == .left {
            leftItem = leftItemOriginal
            if let vi = lastUsedView.item(atRow: row) as? VisibleItem {
                rightItem = vi.item
            }
        } else {
            if let vi = lastUsedView.item(atRow: row) as? VisibleItem {
                leftItem = vi.item
            }
            rightItem = rightItemOriginal
        }
        setBaseFolders(leftItem, right: rightItem)
    }

    // MARK: - Internal Helpers

    // TODO: check clone
    private func setBaseFolders(
        _ leftItem: CompareItem?,
        right rightItem: CompareItem?
    ) {
        guard let leftItem,
              let rightItem else {
            return
        }
        if leftItem.isSymbolicLink || rightItem.isSymbolicLink {
            setBaseFolders(leftItem.path, rightPath: rightItem.path)
        } else {
            leftItemOriginal = leftItem.cloneValidFiles(nil)
            rightItemOriginal = rightItem.cloneValidFiles(nil)
            leftItemOriginal?.linkedItem = rightItemOriginal
            rightItemOriginal?.linkedItem = leftItemOriginal

            let refreshInfo = RefreshInfo(
                initState: false,
                realign: true,
                expandAllFolders: sessionDiff.expandAllFolders
            )
            reloadAll(refreshInfo)

            sessionDiff.leftPath = leftItem.path
            sessionDiff.rightPath = rightItem.path
            synchronizeWindowTitleWithDocumentName()
        }
    }

    private func setBaseFolders(_ leftPath: String?, rightPath: String?) {
        guard let leftPath,
              let rightPath else {
            return
        }
        reloadAll(RefreshInfo(
            initState: true,
            expandAllFolders: sessionDiff.expandAllFolders
        ))

        sessionDiff.leftPath = leftPath
        sessionDiff.rightPath = rightPath
        synchronizeWindowTitleWithDocumentName()
    }
}
