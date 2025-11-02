//
//  NSTableView+Row.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/08/15.
//  Copyright (c) 2015 visualdiffer.com
//

import Foundation

extension NSTableView {
    // Select the row or the closest to it, return the closest row or the original value
    @discardableResult
    @objc func selectRow(
        closestTo row: Int,
        byExtendingSelection: Bool,
        ensureVisible: Bool
    ) -> Int {
        let closestRow = findValid(row: row)

        selectRowIndexes(IndexSet(integer: closestRow), byExtendingSelection: byExtendingSelection)

        if ensureVisible {
            scrollRowToVisible(row)
        }

        return closestRow
    }

    private func findValid(row: Int) -> Int {
        if row < 0 || dataSource == nil {
            return 0
        }
        if let dataSource,
           let rows = dataSource.numberOfRows?(in: self) {
            let lastRow = rows - 1
            if lastRow < row {
                return lastRow
            }
        }
        return row
    }

    @objc var firstVisibleRow: Int {
        guard let superview else {
            return -1
        }
        let bounds = superview.bounds

        return row(at: bounds.origin)
    }

    @objc var lastVisibleRow: Int {
        guard let superview else {
            return -1
        }
        var bounds = superview.bounds
        bounds.origin.y += bounds.size.height - 1

        return row(at: bounds.origin)
    }

    /**
     * If no row is visible then scroll to suggestedRow, if suggested row is -1 scroll to row 0
     */
    @discardableResult
    @objc func ensureRowVisibility(suggestedRow: Int) -> Int {
        var visibleRow = firstVisibleRow

        if visibleRow < 0 {
            if suggestedRow < 0 {
                visibleRow = 0
            } else {
                visibleRow = suggestedRow
            }
        }
        scrollRowToVisible(visibleRow)
        return visibleRow
    }

    @objc func scrollTo(row: Int, center: Bool) {
        if row < 0 {
            return
        }

        // copied from https://stackoverflow.com/a/49192512/195893
        let rowRect = frameOfCell(atColumn: 0, row: row)

        let scrollView = enclosingScrollView
        let headerHeight = headerView?.frame.size.height ?? 0

        let point = if center,
                       let scrollView {
            NSPoint(x: 0, y: rowRect.origin.y - headerHeight + (rowRect.size.height / 2) - (scrollView.frame.size.height / 2))
        } else {
            NSPoint(x: 0, y: rowRect.origin.y - headerHeight)
        }
        scroll(point)
    }
}
