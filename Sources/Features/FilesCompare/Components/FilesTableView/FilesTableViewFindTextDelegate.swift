//
//  FilesTableViewFindTextDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/11/20.
//  Copyright (c) 2020 visualdiffer.com
//

@MainActor
class FilesTableViewFindTextDelegate: NSObject, @preconcurrency FindTextDelegate {
    let view: FilesTableView

    private var lines = [Int]()

    init(view: FilesTableView) {
        self.view = view
    }

    func find(findText: FindText, searchPattern pattern: String) -> Bool {
        guard let matcher = findText.findOptions.matcher(for: pattern),
              let left = view.diffSide?.lines,
              let right = view.linkedView?.diffSide?.lines else {
            return false
        }

        // a line matches when the text is found on any of the two sides
        for i in 0 ..< left.count {
            if matcher(left[i].text) || matcher(right[i].text) {
                lines.append(i)
            }
        }

        return true
    }

    func find(findText _: FindText, moveToMatchIndex index: Int) -> Bool {
        let row = lines[index]

        guard let dataSource = view.dataSource,
              let count = dataSource.numberOfRows?(in: view) else {
            return false
        }

        if row < count {
            select(rows: IndexSet(integer: row))

            return true
        }
        lines.remove(at: index)

        return false
    }

    func numberOfMatches(in _: FindText) -> Int {
        lines.count
    }

    func clearMatches(in _: FindText) {
        lines.removeAll()
    }

    func selectAllMatches(in _: FindText, side: DisplaySide) {
        guard let dataSource = view.dataSource,
              let count = dataSource.numberOfRows?(in: view) else {
            return
        }

        select(rows: IndexSet(lines.filter { $0 < count }), side: side)
    }

    private func select(rows: IndexSet) {
        select(rows: rows, side: view.side)
        select(rows: rows, side: view.side.opposite)
    }

    private func select(rows: IndexSet, side: DisplaySide) {
        // the rows of the two sides are aligned
        guard let firstRow = rows.first,
              let target = side == view.side ? view : view.linkedView else {
            return
        }

        target.scrollRowToVisible(firstRow)
        target.selectRowIndexes(rows, byExtendingSelection: false)
    }
}
