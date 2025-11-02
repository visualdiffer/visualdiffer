//
//  HistoryTableView.swift
//  VisualDiffer
//
//  Created by davide ficano on 20/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

class HistoryTableView: TableViewCommon {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Method not implemented")
    }

    func setup() {
        allowsEmptySelection = true
        allowsColumnReordering = false
        allowsColumnResizing = true
        allowsMultipleSelection = true
        allowsColumnSelection = true
        allowsTypeSelect = true
        usesAlternatingRowBackgroundColors = true

        focusRingType = .none
        allowsExpansionToolTips = true
        columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        autosaveTableColumns = false

        // Needed by drop
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        setDraggingSourceOperationMask(.every, forLocal: true)
        setDraggingSourceOperationMask(.every, forLocal: false)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "HistoryPath"))
        column.title = NSLocalizedString("History", comment: "")
        column.resizingMask = .autoresizingMask
        addTableColumn(column)
        sizeLastColumnToFit()
    }
}
