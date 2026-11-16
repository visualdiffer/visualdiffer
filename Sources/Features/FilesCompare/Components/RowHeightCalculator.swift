//
//  RowHeightCalculator.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

@MainActor
protocol RowHeightDataSource: AnyObject {
    var lineNumberWidth: CGFloat { get }
    var tableFont: NSFont { get }

    func columnWidth(at side: DisplaySide) -> CGFloat
    func line(at row: Int, side: DisplaySide) -> DiffLine?

    func reloadTableData()
}

private let minWidthBeforeWrap: CGFloat = 20.0
private let minHeight: CGFloat = 20.0
private let fontSizeExtraPoint: CGFloat = 4.0
// use the real width of the content text field
private let contentLeadingSpace = LineNumberCellData().contentLeadingSpace

@MainActor
class RowHeightCalculator {
    private var heightCache: [Int: CGFloat] = [:]

    // the column widths the cached heights were computed for
    private var cachedWidths = (left: CGFloat.zero, right: CGFloat.zero)

    // measure with a cell configured like the displayed text field
    // so the line fragment padding is counted, boundingRect ignores it and underestimates the lines
    // wraps also sets lineBreakMode to byWordWrapping
    private let measuringCell = {
        let cell = NSTextFieldCell(textCell: "")
        cell.wraps = true

        return cell
    }()

    // the height of one line, measured once per font
    private var lineHeightFont: NSFont?
    private var cachedLineHeight = CGFloat.zero

    weak var dataSource: RowHeightDataSource?

    var isWordWrapEnabled: Bool = false {
        didSet {
            clearCache()
        }
    }

    func clearCache() {
        heightCache.removeAll(keepingCapacity: true)
        cachedWidths = (0, 0)
    }

    func height(for row: Int) -> CGFloat {
        if let height = heightCache[row] {
            return height
        }
        let height = calculateRowHeight(row)
        heightCache[row] = height

        return height
    }

    private func minimumHeight(of font: NSFont) -> CGFloat {
        max(minHeight, font.pointSize + fontSizeExtraPoint)
    }

    private func calculateCellHeight(forRow row: Int, side: DisplaySide) -> CGFloat {
        guard let dataSource,
              let text = dataSource.line(at: row, side: side)?.text else {
            return 0
        }

        let font = dataSource.tableFont

        if !isWordWrapEnabled {
            return minimumHeight(of: font)
        }

        let lineNumberWidth = dataSource.lineNumberWidth
        let columnWidth = dataSource.columnWidth(at: side)

        let textWidth = columnWidth - lineNumberWidth - contentLeadingSpace

        // some fonts (e.g. Courier 24) have a line taller than the
        // minimum height, so a single line row is the taller of the two
        let lineHeight = singleLineHeight(of: font)
        let singleLineRowHeight = max(minimumHeight(of: font), lineHeight)

        // an empty line is always a single line, skip the measure
        guard textWidth > minWidthBeforeWrap, !text.isEmpty else {
            return singleLineRowHeight
        }

        let textHeight = measuredHeight(of: text, font: font, width: textWidth)

        // do not add extra height to non-wrapped text
        // wrapped text keeps the padding of a single line row, the fixed
        // 20pt threshold doubled one-line rows from about 17pt on and the extra pointSize left an
        // empty line under wrapped text
        return textHeight + singleLineRowHeight - lineHeight
    }

    private func calculateRowHeight(_ row: Int) -> CGFloat {
        let leftHeight = calculateCellHeight(forRow: row, side: .left)
        let rightHeight = calculateCellHeight(forRow: row, side: .right)

        return max(leftHeight, rightHeight)
    }

    func reloadData() {
        clearCache()
        dataSource?.reloadTableData()
    }

    // the caller doesn't know what the heights depend on: without word wrap they are the
    // font line height, so any resize leaves them alone, and with word wrap only a change
    // of the column width makes them stale
    private func reloadDataIfWidthChanged() {
        guard isWordWrapEnabled,
              let dataSource else {
            return
        }

        let widths = (left: dataSource.columnWidth(at: .left), right: dataSource.columnWidth(at: .right))

        if widths == cachedWidths {
            return
        }

        reloadData()
        cachedWidths = widths
    }

    // the column resize arrives during the table layout (where a
    // reload loses the restored selection) and once per panel, so the check is deferred and coalesced
    func scheduleReloadIfWidthChanged() {
        guard isWordWrapEnabled else {
            return
        }

        // the second panel's block finds cachedWidths already updated and does nothing
        DispatchQueue.main.async { [weak self] in
            self?.reloadDataIfWidthChanged()
        }
    }

    private func measuredHeight(of text: String, font: NSFont, width: CGFloat) -> CGFloat {
        measuringCell.font = font
        measuringCell.stringValue = text

        let size = measuringCell.cellSize(
            forBounds: NSRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude)
        )

        return ceil(size.height)
    }

    // the cell measures an empty string as one full line of the font
    private func singleLineHeight(of font: NSFont) -> CGFloat {
        if font != lineHeightFont {
            cachedLineHeight = measuredHeight(of: "", font: font, width: CGFloat.greatestFiniteMagnitude)
            lineHeightFont = font
        }

        return cachedLineHeight
    }
}
