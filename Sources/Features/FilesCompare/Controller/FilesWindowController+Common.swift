//
//  FilesWindowController+Common.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

func swap<T>(_ lhs: inout T, _ rhs: inout T) {
    let tmp = lhs

    lhs = rhs
    rhs = tmp
}

extension FilesWindowController {
    // MARK: - Refresh after edit

    func refreshAfterTextEdit(_ selectedRow: Int = -1) {
        guard let diffResult else {
            return
        }

        // refresh sections otherwise moving between differences can position to wrong line
        diffResult.refreshSections()
        differenceCounters.update(counters: DiffCountersItem.diffCounter(withResult: diffResult))
        cachedLineTextMap.removeAll()

        let selectedRow = min(
            selectedRow < 0 ? lastUsedView.selectedRow : selectedRow,
            diffResult.leftSide.lines.count - 1
        )

        leftView.reloadData()
        rightView.reloadData()

        lastUsedView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: true)
        lastUsedView.scrollRowToVisible(selectedRow)

        updateDetailLines(selectedRow)

        fileThumbnail.needsDisplay = true
    }

    func askReload() -> Bool {
        let informativeLines = [
            NSLocalizedString("Another application has made changes to the file for this document.", comment: ""),
            NSLocalizedString("You can choose to compare using the modified version on the file system, or keep the existing one", comment: ""),
            NSLocalizedString("(Reverting will lose any unsaved changes.)", comment: ""),
        ]

        return NSAlert.showModalConfirm(
            messageText: NSLocalizedString("The file(s) have been changed on the file system. Do you want to reload all modified files?", comment: ""),
            informativeText: informativeLines.joined(separator: "\n"),
            suppressPropertyName: CommonPrefs.Name.confirmReloadFiles.rawValue,
            yesText: NSLocalizedString("Reload", comment: ""),
            noText: NSLocalizedString("Keep", comment: "")
        )
    }

    // MARK: - Details lines

    @objc
    func updateDetailLines(_ row: Int) {
        if row < 0 {
            setColor(for: nil, view: leftDetailsTextView)
            setColor(for: nil, view: rightDetailsTextView)
        } else {
            if let leftSide = leftView.diffSide,
               let rightSide = rightView.diffSide {
                let row = min(row, leftSide.lines.count - 1)
                let oldLine = row < 0 ? nil : leftSide.lines[row]
                let newLine = row < 0 ? nil : rightSide.lines[row]

                setColor(for: oldLine, view: leftDetailsTextView)
                setColor(for: newLine, view: rightDetailsTextView)
            }
        }
    }

    func setColor(for diffLine: DiffLine?, view lineView: LineDetailTextView) {
        // set the text to be sure textStorage has a valid length
        guard let diffLine else {
            lineView.clearContent()
            return
        }

        let lineEnding = scopeBar.showWhitespaces ? "" : diffLine.component.eol.visibleSymbol
        lineView.updateContent(
            diffLine,
            text: getLine(diffLine),
            lineEnding: lineEnding,
            highlightRanges: inlineDisplayRanges(diffLine)
        )
    }

    // MARK: - Cache lines

    // only the text is cached, the offset mapping costs an array per line and is needed
    // by the few changed lines carrying inline differences, so it is rebuilt on demand
    func displayLine(_ diffLine: DiffLine) -> DisplayLine {
        visibleWhitespaces.getString(
            diffLine.component,
            isWhitespacesVisible: scopeBar.showWhitespaces
        )
    }

    func getLine(_ diffLine: DiffLine) -> String {
        if let line = cachedLineTextMap[diffLine] {
            return line
        }
        let line = displayLine(diffLine).text

        cachedLineTextMap[diffLine] = line

        return line
    }

    // the offsets are relative to the text drawn from the given column, so the highlight
    // follows the horizontal scrolling of the panels
    func inlineDisplayRanges(_ diffLine: DiffLine, startingColumn: Int = 0) -> [Range<Int>] {
        guard diffLine.type == .changed, !diffLine.inlineRanges.isEmpty else {
            return []
        }

        let display = displayLine(diffLine)
        let visibleCount = display.text.count - startingColumn

        if visibleCount < 0 {
            return []
        }
        var ranges = [Range<Int>]()

        ranges.reserveCapacity(diffLine.inlineRanges.count)

        for range in diffLine.inlineRanges {
            let lower = max(0, display.displayOffset(for: range.lowerBound) - startingColumn)
            let upper = min(visibleCount, display.displayOffset(for: range.upperBound) - startingColumn)

            if lower < upper {
                ranges.append(lower ..< upper)
            }
        }

        return ranges
    }

    // MARK: - Actions

    @objc
    func reload(_: AnyObject?) {
        guard alertSaveDirtyFiles() else {
            return
        }

        let index = leftView.selectedRowIndexes
        let row = leftView.firstVisibleRow

        reloadAllMove(toFirstDifference: false)

        if row <= leftView.numberOfRows {
            leftView.scrollTo(row: row, center: false)
            leftView.selectRowIndexes(index, byExtendingSelection: false)
        } else {
            moveToDifference(true, showAnim: true, moveToFile: false)
        }
    }

    @objc
    func recompare(_: AnyObject?) {
        guard let diffResult else {
            return
        }

        let row = lastUsedView.selectedRow

        compare(
            leftLines: diffResult.leftSide.nonMissingLineComponents(),
            rightLines: diffResult.rightSide.nonMissingLineComponents(),
            moveToFirstDifference: false
        )

        lastUsedView.scrollTo(row: row, center: true)
        lastUsedView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: true)
    }

    @objc
    func swapSides(_: AnyObject) {
        swap(&sessionDiff.leftPath, &sessionDiff.rightPath)
        swap(&leftView.diffSide, &rightView.diffSide)
        swap(&leftPanelView.fileInfoBar.fileAttrs, &rightPanelView.fileInfoBar.fileAttrs)
        swap(&leftPanelView.fileInfoBar.encoding, &rightPanelView.fileInfoBar.encoding)
        swap(&leftPanelView.fileInfoBar.eol, &rightPanelView.fileInfoBar.eol)

        reloadRowHeights()
        fileThumbnail.needsDisplay = true
    }

    @objc
    func toggleWordWrap(_: AnyObject) {
        setWordWrap(enabled: !rowHeightCalculator.isWordWrapEnabled)
    }

    // MARK: Find Methods

    @objc
    func find(_: AnyObject) {
        window?.makeFirstResponder(scopeBar)
    }

    @objc
    func findPrevious(_: AnyObject) {
        scopeBar.findView.moveToMatch(false)
    }

    @objc
    func findNext(_: AnyObject) {
        scopeBar.findView.moveToMatch(true)
    }

    @objc
    func selectAllFound(_ sender: AnyObject) {
        guard let sender = sender as? NSMenuItem else {
            return
        }

        let side = SelectionSide(menuItem: sender)
        let findView = scopeBar.findView

        if side.contains(.left) {
            findView.delegate?.selectAllMatches(in: findView, side: .left)
        }
        if side.contains(.right) {
            findView.delegate?.selectAllMatches(in: findView, side: .right)
        }
    }

    @objc
    func setLeftReadOnly(_: AnyObject) {
        sessionDiff.leftReadOnly.toggle()
    }

    @objc
    func setRightReadOnly(_: AnyObject) {
        sessionDiff.rightReadOnly.toggle()
    }
}
