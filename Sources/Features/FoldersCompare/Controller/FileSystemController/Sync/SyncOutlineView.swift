//
//  SyncOutlineView.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

@objc class SyncOutlineView: NSOutlineView, NSOutlineViewDataSource, NSOutlineViewDelegate {
    var items: SyncItemsInfo

    @objc init(items: SyncItemsInfo) {
        self.items = items
        super.init(frame: .zero)

        dataSource = self
        delegate = self
        controlSize = .small
        headerView = nil

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("FileName"))

        column.isEditable = false
        column.width = 180
        column.minWidth = 100
        column.maxWidth = 1000
        column.resizingMask = [.autoresizingMask, .userResizingMask]

        addTableColumn(column)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? DescriptionOutlineNode ?? items.nodes else {
            return 0
        }

        return node.children.count
    }

    func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? DescriptionOutlineNode else {
            return false
        }

        return node.isContainer
    }

    func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? DescriptionOutlineNode ?? items.nodes else {
            fatalError("Item must be DescriptionOutlineNode")
        }

        return node.children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? DescriptionOutlineNode,
              let identifier = tableColumn?.identifier else {
            return nil
        }
        let cell = outlineView.makeView(
            withIdentifier: identifier,
            owner: self
        ) as? NSTableCellView ?? createCell(identifier)
        cell.textField?.stringValue = item.text

        return cell
    }

    private func createCell(_ identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView(frame: NSRect(x: 0, y: 0, width: 100, height: 20))
        cell.identifier = identifier

        let textField = NSTextField(frame: cell.bounds)
        textField.autoresizingMask = [.width, .height]

        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        textField.lineBreakMode = .byTruncatingMiddle

        cell.addSubview(textField)
        cell.textField = textField

        return cell
    }
}
