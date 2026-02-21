//
//  FilesWindowController+FilesScopeBar.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController: @preconcurrency FilesScopeBarDelegate {
    // MARK: - FilesScopeBar Delegate

    func filesScopeBar(
        _ filesScopeBar: FilesScopeBar,
        action: FilesScopeBarAction
    ) {
        switch action {
        case .showWhitespaces:
            showWhitespaces(filesScopeBar)
        case .showAllLines:
            showAllLines(filesScopeBar)
        case .showJustMatchingLines:
            showJustMatchingLines(filesScopeBar)
        case .showJustDifferentLines:
            showJustDifferentLines(filesScopeBar)
        }
    }

    @objc
    func showAllLines(_: AnyObject) {
        refreshLinesStatus()
    }

    @objc
    func showJustMatchingLines(_: AnyObject) {
        refreshLinesStatus()
    }

    @objc
    func showJustDifferentLines(_: AnyObject) {
        refreshLinesStatus()
    }

    @objc
    func refreshLinesStatus() {
        guard let diffResult else {
            return
        }
        let diffResultInUse: DiffResult?

        // always use the current selected filter
        switch scopeBar.showLinesFilter {
        case .all:
            currentDiffResult?.resetSectionSeparators()
            diffResultInUse = diffResult
        case .matches:
            filteredDiffResult = DiffResult.justMatchingLines(diffResult)
            diffResultInUse = filteredDiffResult
        case .differences:
            filteredDiffResult = DiffResult.justDifferentLines(diffResult)
            diffResultInUse = filteredDiffResult
        }

        currentDiffResult = diffResultInUse
        let visibleRow = calcVisibleRow(for: diffResultInUse)

        leftView.diffSide = diffResultInUse?.leftSide
        rightView.diffSide = diffResultInUse?.rightSide

        fileThumbnail.diffResult = diffResult
        fileThumbnail.linesCount = currentDiffResult?.leftSide.lines.count ?? 0
        fileThumbnail.view = leftView
        fileThumbnail.needsDisplay = true

        reloadRowHeights()

        leftView.scrollTo(row: visibleRow, center: true)
    }

    func calcVisibleRow(for destDiffResult: DiffResult?) -> Int {
        guard let destDiffResult,
              let currentDiffResult else {
            return 0
        }
        // determine the current line number
        let currentVisibleRow = leftView.firstVisibleRow

        if currentDiffResult === destDiffResult {
            return currentVisibleRow
        }
        let count = currentDiffResult.leftSide.lines.count
        var lineNumber = -1
        var diffLines: [DiffLine]?

        // Find the first valid line number (eg not missing lines) on left or right
        for row in currentVisibleRow ..< count {
            var line = currentDiffResult.leftSide.lines[row]
            if line.number > 0 {
                lineNumber = line.number
                diffLines = destDiffResult.leftSide.lines
                break
            }
            line = currentDiffResult.rightSide.lines[row]
            if line.number > 0 {
                lineNumber = line.number
                diffLines = destDiffResult.rightSide.lines
                break
            }
        }

        // Now find the row from selected diffLines
        return diffLines?.firstIndex { $0.number >= lineNumber } ?? 0
    }
}
