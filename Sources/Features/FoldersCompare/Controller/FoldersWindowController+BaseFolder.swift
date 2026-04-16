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
            if let pathURLs = baseURLFromPathView(otherSide: false) {
                setBaseFolders(pathURLs.leftURL?.osPath, rightPath: pathURLs.rightURL?.osPath)
            }

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
            if let pathURLs = baseURLFromPathView(otherSide: true) {
                setBaseFolders(pathURLs.leftURL?.osPath, rightPath: pathURLs.rightURL?.osPath)
            }
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

            sessionDiff.leftPath = leftItem.path
            sessionDiff.rightPath = rightItem.path
            synchronizeWindowTitleWithDocumentName()

            let refreshInfo = RefreshInfo(
                initState: false,
                realign: true,
                expandAllFolders: sessionDiff.expandAllFolders
            )
            reloadAll(refreshInfo)
        }
    }

    private func setBaseFolders(_ leftPath: String?, rightPath: String?) {
        guard let leftPath,
              let rightPath else {
            return
        }

        sessionDiff.leftPath = leftPath
        sessionDiff.rightPath = rightPath
        synchronizeWindowTitleWithDocumentName()

        reloadAll(RefreshInfo(
            initState: true,
            expandAllFolders: sessionDiff.expandAllFolders
        ))
    }

    private func baseURLFromPathView(otherSide: Bool) -> (leftURL: URL?, rightURL: URL?)? {
        if let leftClickedURL = leftPanelView.pathView.pathControl.clickedPath {
            if otherSide {
                return (leftPanelView.pathView.pathControl.url, leftClickedURL)
            }
            return (leftClickedURL, rightPanelView.pathView.pathControl.url)
        }

        if let rightClickedURL = rightPanelView.pathView.pathControl.clickedPath {
            if otherSide {
                return (rightClickedURL, rightPanelView.pathView.pathControl.url)
            }
            return (leftPanelView.pathView.pathControl.url, rightClickedURL)
        }

        return nil
    }
}
