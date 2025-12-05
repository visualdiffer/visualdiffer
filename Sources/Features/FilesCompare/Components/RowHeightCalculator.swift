//
//  RowHeightCalculator.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

@MainActor protocol RowHeightDataSource: AnyObject {
    var lineNumberWidth: CGFloat { get }
    var tableFont: NSFont { get }

    func columnWidth(at side: DisplaySide) -> CGFloat
    func line(at row: Int, side: DisplaySide) -> DiffLine?

    func reloadTableData()
}

private let minWidthBeforeWrap: CGFloat = 20.0
private let minHeight: CGFloat = 20.0
private let fontSizeExtraPoint: CGFloat = 4.0

private let horizontalPadding: CGFloat = 12.0
private let verticalPadding: CGFloat = 4.0

@MainActor class RowHeightCalculator {
    private var heightCache: [Int: CGFloat] = [:]

    weak var dataSource: RowHeightDataSource?

    var isWordWrapEnabled: Bool = false {
        didSet {
            clearCache()
        }
    }

    func clearCache() {
        heightCache.removeAll(keepingCapacity: true)
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

        let textWidth = columnWidth - lineNumberWidth - horizontalPadding

        guard textWidth > minWidthBeforeWrap else {
            return minimumHeight(of: font)
        }

        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attributes)

        let rect = attributedString.boundingRect(
            with: NSSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )

        let textHeight = ceil(rect.height)

        // do not add extra height to non-wrapped text
        if textHeight < minHeight {
            return minimumHeight(of: font)
        }

        return textHeight + verticalPadding + font.pointSize
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
}
