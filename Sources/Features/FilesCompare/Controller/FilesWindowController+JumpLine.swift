//
//  FilesWindowController+JumpLine.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController {
    @objc
    func jumpToLine(_: AnyObject) {
        guard let window,
              let currentDiffResult else {
            return
        }
        let jumpToLineWindow = JumpToLineWindow.createSheet()

        jumpToLineWindow.lineNumber = findStartJumpLine()
        jumpToLineWindow.side = lastUsedView.side
        jumpToLineWindow.leftMaxLineNumber = currentDiffResult.leftSide.linesCount
        jumpToLineWindow.rightMaxLineNumber = currentDiffResult.rightSide.linesCount

        jumpToLineWindow.beginSheet(window) {
            self.jumpToLineHandler($0, jumpToLineWindow: jumpToLineWindow)
        }
    }

    private func findStartJumpLine() -> Int {
        let row = lastUsedView.selectedRow

        if row < 0 {
            return 1
        }

        guard let arr = lastUsedView.diffSide?.lines else {
            return 1
        }
        let lineNumber = arr[row].number

        if lineNumber < 0 {
            return 1
        }
        return lineNumber
    }

    func jumpToLineHandler(
        _ returnCode: NSApplication.ModalResponse,
        jumpToLineWindow: JumpToLineWindow
    ) {
        guard let currentDiffResult,
              returnCode == .OK else {
            return
        }
        var row = -1
        var view: FilesTableView
        switch jumpToLineWindow.side {
        case .left:
            row = currentDiffResult.leftSide.findLineIndex(by: jumpToLineWindow.lineNumber) ?? 0
            view = leftView
        case .right:
            row = currentDiffResult.rightSide.findLineIndex(by: jumpToLineWindow.lineNumber) ?? 0
            view = rightView
        }
        if row >= 0 {
            view.scrollTo(row: row, center: true)
            view.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            window?.makeFirstResponder(view)
        }
    }
}
