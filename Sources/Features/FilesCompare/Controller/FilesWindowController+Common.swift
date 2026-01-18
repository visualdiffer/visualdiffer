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
        cachedLineTextMap.removeAllObjects()

        let selectedRow = selectedRow < 0 ? lastUsedView.selectedRow : selectedRow

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

    @objc func updateDetailLines(_ row: Int) {
        if row < 0 {
            setColor(for: nil, view: leftDetailsTextView)
            setColor(for: nil, view: rightDetailsTextView)
        } else {
            if let leftSide = leftView.diffSide,
               let rightSide = rightView.diffSide {
                let oldLine = leftSide.lines[row]
                let newLine = rightSide.lines[row]

                setColor(for: oldLine, view: leftDetailsTextView)
                setColor(for: newLine, view: rightDetailsTextView)
            }
        }
    }

    func setColor(for diffLine: DiffLine?, view lineView: NSTextView) {
        // set the text to be sure textStorage has a valid length
        guard let diffLine else {
            lineView.string = ""
            return
        }
        lineView.string = getLine(diffLine) + (scopeBar.showWhitespaces ? "" : diffLine.component.eol.visibleSymbol)

        if let colors = diffLine.colors {
            lineView.setTextColor(colors.text, backgroundColor: colors.background)
        }
    }

    // MARK: - Cache lines

    func getLine(_ diffLine: DiffLine) -> String {
        if let line = cachedLineTextMap.object(forKey: diffLine) as? String {
            return line as String
        }
        let line = visibleWhitespaces.getString(
            diffLine.component,
            isWhitespacesVisible: scopeBar.showWhitespaces
        )
        cachedLineTextMap.setObject(line as NSString, forKey: diffLine)

        return line
    }

    // MARK: - Actions

    @objc func reload(_: AnyObject?) {
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
            moveToDifference(true, showAnim: true)
        }
    }

    @objc func recompare(_: AnyObject?) {
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

    @objc func swapSides(_: AnyObject) {
        swap(&sessionDiff.leftPath, &sessionDiff.rightPath)
        swap(&leftView.diffSide, &rightView.diffSide)
        swap(&leftPanelView.fileInfoBar.fileAttrs, &rightPanelView.fileInfoBar.fileAttrs)
        swap(&leftPanelView.fileInfoBar.encoding, &rightPanelView.fileInfoBar.encoding)
        swap(&leftPanelView.fileInfoBar.eol, &rightPanelView.fileInfoBar.eol)

        reloadRowHeights()
        fileThumbnail.needsDisplay = true
    }

    @objc func toggleWordWrap(_: AnyObject) {
        setWordWrap(enabled: !rowHeightCalculator.isWordWrapEnabled)
    }

    // MARK: Find Methods

    @objc func find(_: AnyObject) {
        window?.makeFirstResponder(scopeBar)
    }

    @objc func findPrevious(_: AnyObject) {
        scopeBar.findView.moveToMatch(false)
    }

    @objc func findNext(_: AnyObject) {
        scopeBar.findView.moveToMatch(true)
    }

    @objc func setLeftReadOnly(_: AnyObject) {
        sessionDiff.leftReadOnly.toggle()
    }

    @objc func setRightReadOnly(_: AnyObject) {
        sessionDiff.rightReadOnly.toggle()
    }
}
