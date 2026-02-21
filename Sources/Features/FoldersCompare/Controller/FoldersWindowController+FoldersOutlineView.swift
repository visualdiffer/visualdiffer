//
//  FoldersWindowController+FoldersOutlineView.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

import os.log

extension FoldersWindowController: NSOutlineViewDelegate,
    NSOutlineViewDataSource,
    FoldersOutlineViewDelegate,
    OutlineViewItemDelegate {
    @objc var leftView: FoldersOutlineView {
        leftPanelView.treeView
    }

    @objc var rightView: FoldersOutlineView {
        rightPanelView.treeView
    }

    // MARK: - NSOutlineView delegates messages

    public func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        // left and right are symmetric so subfolders count is identical and we don't need to check the outlineView
        guard let children = item as? VisibleItem ?? leftVisibleItems else {
            return 0
        }

        return children.children.count
    }

    public func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
        // left and right are symmetric so expandable status is identical and we don't need to check the outlineView
        guard let child = (item as? VisibleItem)?.item else {
            return false
        }

        if child.isFolder {
            if child.isSymbolicLink {
                return sessionDiff.followSymLinks
            }
            return true
        }
        return false
    }

    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let leftVisibleItems,
              let vi = outlineView == leftView ? leftVisibleItems : leftVisibleItems.linkedItem else {
            fatalError("leftVisibleItems can't be nil")
        }

        let children = item as? VisibleItem ?? vi
        let arr = children.children

        if index >= arr.count {
            #if DEBUG
                if let badItem = vi.item.path != nil ? vi.item : vi.linkedItem?.item {
                    Logger.ui.error("Saved from array out of bound for index \(index) path \(badItem.path ?? "") subs count \(badItem.visibleItem?.children.count ?? 0)")
                }
            #endif
            return arr.last ?? children
        }

        return arr[index]
    }

    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let tableColumn,
              let itemCompare = (item as? VisibleItem)?.item,
              let result = outlineView.makeView(
                  withIdentifier: tableColumn.identifier,
                  owner: nil
              ) as? CompareItemTableCellView else {
            return nil
        }

        result.text.stringValue = ""
        result.toolTip = ""
        result.text.toolTip = ""

        if tableColumn.identifier == .Folders.cellName {
            result.fileName(
                itemCompare,
                font: currentFont,
                isExpanded: outlineView.isItemExpanded(item),
                followSymLinks: sessionDiff.followSymLinks,
                hideEmptyFolders: hideEmptyFolders
            )
        } else if tableColumn.identifier == .Folders.cellSize {
            let tooltip = itemCompare.fileSizeDescription
            result.toolTip = tooltip
            result.text.toolTip = tooltip
            result.fileSize(
                itemCompare,
                font: currentFont,
                columnWidth: tableColumn.width
            )
        } else if tableColumn.identifier == .Folders.cellModified {
            result.fileDate(
                itemCompare,
                date: itemCompare.fileModificationDate,
                font: currentFont,
                dateFormat: CommonPrefs.shared.folderViewDateFormat as String
            )
        }

        // No matter if the row is selected, its color is taken from the status
        let type = itemCompare.compareChangeType(
            tableColumn.identifier,
            followSymLinks: sessionDiff.followSymLinks
        )
        if type != .unknown {
            result.text.textColor = CommonPrefs.shared.changeTypeColor(type)?.text
        }
        return result
    }

    public func outlineView(_: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        // draw the selection
        let result = CompareItemTableRowView(frame: .zero)
        result.item = (item as? VisibleItem)?.item

        return result
    }

    public func outlineViewColumnDidResize(_ notification: Notification) {
        // don't resize other view if alternate key is down
        let isOptionDown = NSApp.currentEvent?.modifierFlags.contains(.option) ?? false
        if dontResizeColumns || isOptionDown {
            return
        }

        guard let column = notification.userInfo?["NSTableColumn"] as? NSTableColumn,
              let view = (notification.object as? FoldersOutlineView)?.linkedView as? FoldersOutlineView else {
            return
        }

        dontResizeColumns = true
        view.tableColumn(withIdentifier: column.identifier)?.width = column.width
        dontResizeColumns = false
    }

    public func outlineView(_: NSOutlineView, didAdd rowView: NSTableRowView, forRow _: Int) {
        // folders background is not changed so check if this is a file (or a filtered file/folder)
        if let item = (rowView as? CompareItemTableRowView)?.item,
           item.isValidFile, item.isFile || item.isFiltered {
            let type = item.compareChangeType(
                nil,
                followSymLinks: sessionDiff.followSymLinks
            )
            if type != .unknown {
                if let color = CommonPrefs.shared.changeTypeColor(type)?.background {
                    rowView.backgroundColor = color
                }
            }
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, sortDescriptorsDidChange _: [NSSortDescriptor]) {
        if leftVisibleItems == nil {
            return
        }
        if running {
            return
        }
        if outlineView.sortDescriptors.isEmpty {
            return
        }

        guard let folderView = outlineView as? FoldersOutlineView else {
            return
        }

        // remove the sort indicator from the other side
        folderView.linkedView?.sortDescriptors = []

        sessionDiff.updateSortColumn(
            from: outlineView.sortDescriptors[0],
            side: outlineView == leftView ? .left : .right
        )

        sortBySessionColumn()

        leftView.reloadData()
        rightView.reloadData()
    }

    @objc
    func sortBySessionColumn() {
        guard let leftVisibleItems else {
            return
        }

        guard let vi = sessionDiff.currentSortSide == .left ? leftVisibleItems : leftVisibleItems.linkedItem else {
            return
        }

        let ascending = sessionDiff.isCurrentSortAscending

        switch sessionDiff.currentSortColumn {
        case .name:
            vi.sort(byFileName: ascending, ignoreCase: true, followSymLinks: sessionDiff.followSymLinks)
        case .size:
            vi.sort(byFileSize: ascending, ignoreCase: true)
        case .modificationDate:
            vi.sort(byDate: ascending, ignoreCase: true)
        }
    }

    // MARK: - Drag&Drop

    public func outlineView(_ outlineView: NSOutlineView, validateDrop info: any NSDraggingInfo, proposedItem _: Any?, proposedChildIndex _: Int) -> NSDragOperation {
        let pasteboard = info.draggingPasteboard
        var result: NSDragOperation = []

        if (info.draggingSource as? FoldersOutlineView) === outlineView {
            // The drag is originating from ourselves, discard it
            return result
        }
        outlineView.setDropItem(nil, dropChildIndex: NSOutlineViewDropOnItemIndex)

        if pasteboard.availableType(from: [.fileURL]) == nil {
            return result
        }
        guard let arr = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return result
        }
        let path1 = arr[0].osPath
        var isDir = ObjCBool(false)
        let isValidPath1 = FileManager.default.fileExists(atPath: path1, isDirectory: &isDir) && isDir.boolValue

        if arr.count < 2 {
            if isValidPath1 {
                result = .copy
            }
        } else {
            let path2 = arr[1].osPath
            let isValidPath2 = FileManager.default.fileExists(atPath: path2, isDirectory: &isDir) && isDir.boolValue
            if isValidPath1, isValidPath2 {
                result = .copy
            }
        }

        return result
    }

    public func outlineView(_ outlineView: NSOutlineView, acceptDrop info: any NSDraggingInfo, item _: Any?, childIndex _: Int) -> Bool {
        guard let view = outlineView as? FoldersOutlineView else {
            return false
        }

        let pasteboard = info.draggingPasteboard

        if pasteboard.availableType(from: [.fileURL]) == nil {
            return false
        }
        guard let arr = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return false
        }
        if arr.count < 2 {
            if let path = arr.last?.osPath {
                if view.side == .left {
                    sessionDiff.leftPath = path
                } else {
                    sessionDiff.rightPath = path
                }
            }
        } else {
            sessionDiff.leftPath = arr[0].osPath
            sessionDiff.rightPath = arr[1].osPath
        }

        reloadAll(RefreshInfo(
            initState: true,
            expandAllFolders: sessionDiff.expandAllFolders
        ))

        synchronizeWindowTitleWithDocumentName()

        return true
    }

    public func outlineView(_: NSOutlineView, pasteboardWriterForItem item: Any) -> (any NSPasteboardWriting)? {
        guard let vi = item as? VisibleItem,
              let url = vi.item.toUrl() else {
            return nil
        }

        return url as NSURL
    }

    // MARK: - FoldersOutlineViewDelegate

    public func foldersOutlineView(_ view: FoldersOutlineView, doubleClickFileObject clickedRow: Int) {
        guard let itemRow = view.item(atRow: clickedRow) as? VisibleItem else {
            return
        }
        let leftItem = view.side == .left ? itemRow.item : itemRow.item.linkedItem
        guard let leftItem,
              let rightItem = leftItem.linkedItem else {
            return
        }

        do {
            if let document = try VDDocumentController.shared.openDifferDocument(
                leftUrl: leftItem.toUrl(),
                rightUrl: rightItem.toUrl()
            ) {
                addChildDocument(document)
            }
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    public func selectionChanged(in view: FoldersOutlineView) {
        // we can't use outlineViewSelectionDidChange because it is called
        // before the notification declared into outline subclass
        // So we use our notification sent from outline subclass
        updateBottomBar(view)
        updateStatusBar()
        previewPanel?.reloadData()
    }

    public func setLastUsedViewResponder(_ view: FoldersOutlineView) {
        lastUsedView = view

        if let toolbarItems = window?.toolbar?.visibleItems {
            for item in toolbarItems {
                updateToolbarButton(item)
            }
        }
    }

    // MARK: - OutlineViewExpandItemDelegate implementation

    public func itemDidExpand(_ item: Any?, outlineView: NSOutlineView) {
        let row = outlineView.row(forItem: item)
        // View based TableView must be informed to redraw the view
        // otherwise the folder image doesn't toggle its expanded/collapsed status
        // For view based TableView the outlineView.reloadItem() method seems not be called (is it a bug???)
        // so we reload using [outlineView reloadDataForRowIndexes:columnIndexes]
        outlineView.reloadData(
            forRowIndexes: IndexSet(integer: row),
            columnIndexes: IndexSet(integersIn: 0 ..< outlineView.numberOfColumns)
        )
        if let outlineView = outlineView as? FoldersOutlineView {
            updateBottomBar(outlineView)
        }
    }

    public func itemDidCollapse(_ item: Any?, outlineView: NSOutlineView) {
        itemDidExpand(item, outlineView: outlineView)
    }
}
