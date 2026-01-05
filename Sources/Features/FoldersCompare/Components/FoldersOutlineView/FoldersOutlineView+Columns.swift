//
//  FoldersOutlineView+Columns.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersOutlineView {
    func addColumns() {
        var column = NSTableColumn(identifier: .Folders.cellName)
        column.isEditable = false
        column.width = 180
        column.minWidth = 100
        column.maxWidth = 1000
        column.resizingMask = [.autoresizingMask, .userResizingMask]
        column.title = NSLocalizedString("Name", comment: "")
        column.headerCell.alignment = .left
        column.headerCell.lineBreakMode = .byTruncatingTail

        addTableColumn(column)

        column = NSTableColumn(identifier: .Folders.cellSize)
        column.isEditable = false
        column.width = 80
        column.minWidth = 40
        column.maxWidth = 1000
        column.resizingMask = [.autoresizingMask, .userResizingMask]
        column.title = NSLocalizedString("Size", comment: "")
        column.headerCell.alignment = .right
        column.headerCell.lineBreakMode = .byTruncatingTail

        addTableColumn(column)

        column = NSTableColumn(identifier: .Folders.cellModified)
        column.isEditable = false
        column.width = 250
        column.minWidth = 100
        column.maxWidth = CGFLOAT_MAX
        column.resizingMask = [.autoresizingMask, .userResizingMask]
        column.title = NSLocalizedString("Modified", comment: "")
        column.headerCell.alignment = .left
        column.headerCell.lineBreakMode = .byTruncatingTail

        addTableColumn(column)
    }

    func adjustColumnsWidths(
        _ font: NSFont,
        dateFormatTemplate: String
    ) {
        var totalWidth = 0.0

        for col in tableColumns {
            totalWidth += col.width
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(
            fromTemplate: dateFormatTemplate,
            options: 0,
            locale: Locale.current
        )

        let textAttrs = [NSAttributedString.Key.font: font]
        let dateCellWidth = dateFormatter.widthOfLongestDateStringWithLevel(attrs: textAttrs)
            + NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy)

        let fileSizeFormatter = FileSizeFormatter(showInBytes: true, showUnitForBytes: false)
        let sizeCellWidth = (fileSizeFormatter.string(from: NSNumber(value: 999_999_999_999)) as? NSString)?
            .size(withAttributes: textAttrs).width ?? 0

        tableColumn(withIdentifier: .Folders.cellName)?.width = totalWidth - dateCellWidth - sizeCellWidth
        tableColumn(withIdentifier: .Folders.cellSize)?.width = sizeCellWidth
        tableColumn(withIdentifier: .Folders.cellModified)?.width = dateCellWidth

        outlineTableColumn = tableColumns[0]
    }

    func setupColumnsSort() {
        tableColumn(withIdentifier: .Folders.cellName)?
            .sortDescriptorPrototype = NSSortDescriptor(
                key: "fileName",
                ascending: true,
                selector: #selector(NSString.compare(_:))
            )
        tableColumn(withIdentifier: .Folders.cellSize)?
            .sortDescriptorPrototype = NSSortDescriptor(
                key: "fileSize",
                ascending: true,
                selector: #selector(NSString.compare(_:))
            )
        tableColumn(withIdentifier: .Folders.cellModified)?
            .sortDescriptorPrototype = NSSortDescriptor(
                key: "fileModificationDate",
                ascending: true,
                selector: #selector(NSString.compare(_:))
            )
    }
}
