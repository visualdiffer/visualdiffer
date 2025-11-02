//
//  FilesTableViewFindTextDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/11/20.
//  Copyright (c) 2020 visualdiffer.com
//

@MainActor @objc class FilesTableViewFindTextDelegate: NSObject, @preconcurrency FindTextDelegate {
    let view: FilesTableView

    private var lines = [Int]()

    @objc init(view: FilesTableView) {
        self.view = view
    }

    func find(findText _: FindText, searchPattern pattern: String) -> Bool {
        let globPattern = pattern.convertGlobMetaCharsToRegexpMetaChars()
        guard let re = try? NSRegularExpression(
            pattern: globPattern,
            options: .caseInsensitive
        ),
            let left = view.diffSide?.lines,
            let right = view.linkedView?.diffSide?.lines else {
            return false
        }

        for i in 0 ..< left.count {
            var line = left[i].text
            var range = re.rangeOfFirstMatch(
                in: line,
                options: [],
                range: NSRange(location: 0, length: line.count)
            )
            if range.location == NSNotFound {
                line = right[i].text
                range = re.rangeOfFirstMatch(
                    in: line,
                    options: [],
                    range: NSRange(location: 0, length: line.count)
                )
            }

            if range.location != NSNotFound {
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
            view.scrollRowToVisible(row)
            let indexes = IndexSet(integer: row)
            view.selectRowIndexes(indexes, byExtendingSelection: false)
            view.linkedView?.selectRowIndexes(indexes, byExtendingSelection: false)

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
}
