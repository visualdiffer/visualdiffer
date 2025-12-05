//
//  FilesWindowController+RowHeightDataSource.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController: RowHeightDataSource {
    var tableFont: NSFont {
        currentFont
    }

    func columnWidth(at side: DisplaySide) -> CGFloat {
        let panel = side == .left ? leftPanelView : rightPanelView

        return if let column = panel.treeView.tableColumns.first {
            column.width
        } else {
            max(panel.scrollView.bounds.width, 100)
        }
    }

    func line(at row: Int, side: DisplaySide) -> DiffLine? {
        guard let currentDiffResult else {
            return nil
        }
        let diffSide = side == .left ? currentDiffResult.leftSide : currentDiffResult.rightSide

        return diffSide.lines[row]
    }

    func reloadTableData() {
        leftView.reloadData()
        rightView.reloadData()
    }

    func reloadRowHeights() {
        updateRowHeights()

        rowHeightCalculator.reloadData()
    }

    private func calculateLineNumberWidth() -> CGFloat {
        // count is indentical on left and right so we can use only the left lines count
        // no matters if the missing lines increase the count
        let maxLineCount = currentDiffResult?.leftSide.lines.count ?? 0

        var attributes = [NSAttributedString.Key: Any]()
        attributes[.font] = currentFont

        let str = String(format: "%lld", max(maxLineCount, 100)) as NSString

        return str.size(withAttributes: attributes).width
    }

    func updateRowHeights(clearCache: Bool = true) {
        lineNumberWidth = calculateLineNumberWidth()
        if clearCache {
            rowHeightCalculator.clearCache()
        }
    }

    // MARK: - Helper methods

    func setupHeightSynchronizer() {
        rowHeightCalculator.dataSource = self

        updateRowHeights()
    }

    func setWordWrap(enabled: Bool) {
        rowHeightCalculator.isWordWrapEnabled = enabled

        let row = lastUsedView.firstVisibleRow

        leftPanelView.reloadTreeData()
        rightPanelView.reloadTreeData()

        lastUsedView.scrollTo(row: row, center: false)

        leftPanelView.columnSlider.isHidden = enabled
        leftPanelView.columnSlider.doubleValue = 0

        rightPanelView.columnSlider.isHidden = enabled
        rightPanelView.columnSlider.doubleValue = 0

        updateToolbar()
    }
}
