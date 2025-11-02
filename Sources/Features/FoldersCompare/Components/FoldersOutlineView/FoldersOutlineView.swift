//
//  FoldersOutlineView.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

import Quartz

@MainActor protocol FoldersOutlineViewDelegate: NSOutlineViewDelegate {
    func foldersOutlineView(_ view: FoldersOutlineView, doubleClickFileObject clickedRow: Int)
    func selectionChanged(in view: FoldersOutlineView)
    func setLastUsedViewResponder(_ view: FoldersOutlineView)
}

public class FoldersOutlineView: NSOutlineView, @preconcurrency DisplayPositionable, ViewLinkable {
    private var _selectionInfo: FolderSelectionInfo?

    var selectionInfo: FolderSelectionInfo {
        if _selectionInfo == nil {
            _selectionInfo = FolderSelectionInfo(view: self)
        }
        // swiftlint:disable:next force_unwrapping
        return _selectionInfo!
    }

    private var lockExpand = false

    var linkedView: FoldersOutlineView?
    var side: DisplaySide = .left

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        autoresizesOutlineColumn = false
        indentationPerLevel = 16
        indentationMarkerFollowsCell = true
        autosaveExpandedItems = false

        floatsGroupRows = true
        allowsColumnReordering = true
        allowsColumnResizing = true

        focusRingType = .none
        allowsExpansionToolTips = true
        columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        autosaveTableColumns = false
        rowSizeStyle = .custom
        autoresizingMask = [.width, .height]
        intercellSpacing = NSSize(width: 3, height: 2)
        allowsMultipleSelection = true

        // Needed by drop
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        setDraggingSourceOperationMask(.every, forLocal: true)
        setDraggingSourceOperationMask(.every, forLocal: false)

        doubleAction = #selector(handleDoubleClick)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tableSelectionChanged),
            name: NSOutlineView.selectionDidChangeNotification,
            object: self
        )
    }

    @objc func tableSelectionChanged(_ notification: Notification) {
        _selectionInfo = nil

        if let delegate = delegate as? FoldersOutlineViewDelegate,
           let view = notification.object as? FoldersOutlineView {
            delegate.selectionChanged(in: view)
        }
    }

    // MARK: - Keys and mouse handlers

    func handleEnterKeypressed(_ selectedRow: Int) {
        var view = self
        guard var itemRow = view.item(atRow: selectedRow) as? VisibleItem else {
            return
        }
        var item = itemRow.item

        if !item.isValidFile {
            guard let linkedView = view.linkedView,
                  let linkedItemRow = linkedView.item(atRow: selectedRow) as? VisibleItem else {
                return
            }
            view = linkedView
            itemRow = linkedItemRow
            item = itemRow.item
        }
        if item.isFile {
            (delegate as? FoldersOutlineViewDelegate)?.foldersOutlineView(view, doubleClickFileObject: selectedRow)
        } else if item.isFolder {
            if view.isItemExpanded(itemRow) {
                view.collapseItem(itemRow)
            } else {
                view.expandItem(itemRow)
            }
        }
    }

    @objc func handleDoubleClick(_ sender: AnyObject) {
        if clickedRow != -1 { // make sure double click was not in table header
            handleEnterKeypressed(sender.clickedRow)
        }
    }

    override public func keyDown(with event: NSEvent) {
        guard let str = event.charactersIgnoringModifiers,
              !str.isEmpty else {
            super.keyDown(with: event)
            return
        }
        let key = str[str.startIndex].asciiValue ?? 0

        if key == NSCarriageReturnCharacter || key == NSEnterCharacter {
            handleEnterKeypressed(selectedRow)
        } else if event.keyCode == KeyCode.forwardDeleteCharacter {
            // see http://www.evernote.com/shard/s106/sh/1ed6fa73-10bd-445e-a086-0c8fcdf1af43/0285d57405aa350a98fcb5c6ffc09067
            (delegate as? FoldersOutlineViewContextMenu)?.deleteFiles(nil)
        } else if str == " " {
            QLPreviewPanel.toggle()
        } else {
            super.keyDown(with: event)
        }
    }

    override public func draggingSession(_: NSDraggingSession, sourceOperationMaskFor _: NSDraggingContext) -> NSDragOperation {
        // this is necessary otherwise dragging files to finder move them instead of copy
        .copy
    }

    // MARK: - Menu Actions

    func selectBy(type: CompareChangeType) {
        var indexes = IndexSet()

        for row in 0 ..< numberOfRows {
            if let vi = item(atRow: row) as? VisibleItem {
                let item = vi.item
                if item.isFile, item.isValidFile, item.type == type {
                    indexes.insert(row)
                }
            }
        }
        selectRowIndexes(indexes, byExtendingSelection: false)
    }

    func selectAll(files: Bool, folders: Bool, byExtendingSelection: Bool) {
        var indexes = IndexSet()

        for row in 0 ..< numberOfRows {
            if let vi = item(atRow: row) as? VisibleItem {
                let item = vi.item
                if item.isValidFile, files && item.isFile || (folders && item.isFolder) {
                    indexes.insert(row)
                }
            }
        }
        selectRowIndexes(indexes, byExtendingSelection: byExtendingSelection)
    }

    func invertSelection() {
        var indexes = IndexSet()

        for row in 0 ..< numberOfRows {
            if let vi = item(atRow: row) as? VisibleItem {
                let item = vi.item
                if item.isValidFile, !isRowSelected(row) {
                    indexes.insert(row)
                }
            }
        }
        selectRowIndexes(indexes, byExtendingSelection: false)
    }

    func selectedItems() -> [CompareItem] {
        let indexes = selectedRowIndexes
        var arr = [CompareItem]()
        arr.reserveCapacity(indexes.count)

        for row in indexes {
            if let vi = item(atRow: row) as? VisibleItem {
                let item = vi.item
                if item.isValidFile {
                    arr.append(item)
                }
            }
        }

        return CompareItem.findLeafPaths(arr)
    }

    override public func becomeFirstResponder() -> Bool {
        (delegate as? FoldersOutlineViewDelegate)?.setLastUsedViewResponder(self)
        return super.becomeFirstResponder()
    }

    // MARK: - Expand/Collapse notifiers

    override public func expandItem(_ item: Any?, expandChildren: Bool) {
        guard let delegate = delegate as? OutlineViewItemDelegate else {
            return
        }
        if lockExpand {
            return
        }

        super.expandItem(item, expandChildren: expandChildren)

        let vi = item as? VisibleItem

        lockExpand = true
        linkedView?.expandItem(vi?.linkedItem, expandChildren: expandChildren)
        lockExpand = false

        delegate.itemDidExpand(vi, outlineView: self)
    }

    override public func collapseItem(_ item: Any?, collapseChildren: Bool) {
        guard let delegate = delegate as? OutlineViewItemDelegate else {
            return
        }
        if lockExpand {
            return
        }
        super.collapseItem(item, collapseChildren: collapseChildren)

        let vi = item as? VisibleItem

        lockExpand = true
        linkedView?.collapseItem(vi?.linkedItem, collapseChildren: collapseChildren)
        lockExpand = false

        delegate.itemDidCollapse(vi, outlineView: self)
    }

    override public func makeView(withIdentifier identifier: NSUserInterfaceItemIdentifier, owner _: Any?) -> NSView? {
        // the owner is not used
        var view = super.makeView(withIdentifier: identifier, owner: nil)

        if view != nil {
            return view
        }
        if identifier == .Folders.cellName {
            view = CompareItemTableCellView(icon: true)
        } else if identifier == .Folders.cellSize {
            view = CompareItemTableCellView(icon: false)
        } else if identifier == .Folders.cellModified {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yy HH:mm"
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short

            let cellView = CompareItemTableCellView(icon: false)
            cellView.text.formatter = dateFormatter
            view = cellView
        }
        view?.identifier = identifier

        return view
    }
}
