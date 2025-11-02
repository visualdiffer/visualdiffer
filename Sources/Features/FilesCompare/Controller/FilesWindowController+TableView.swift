//
//  FilesWindowController+TableView.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

@MainActor extension FilesWindowController: NSTableViewDataSource,
    NSTableViewDelegate,
    FilesTableViewDelegate,
    TableViewContextMenuDelegate {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        (tableView as? FilesTableView)?.diffSide?.lines.count ?? 0
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let filesTableView = tableView as? FilesTableView,
              let identifier = tableColumn?.identifier,
              let diffSide = filesTableView.diffSide else {
            return nil
        }
        let arr = diffSide.lines
        let diffLine = arr[row]

        let view = tableView.makeView(withIdentifier: identifier, owner: nil) as? LineNumberTableCellView ?? LineNumberTableCellView()

        view.diffLine = diffLine
        view.font = treeViewFont()
        view.isSelected = tableView.isRowSelected(row)
        view.formattedText = formattedText(diffLine)
        view.setMinBoxWidthByLineCount(diffSide.lines.count)

        return view
    }

    public func tableView(_: NSTableView, rowViewForRow _: Int) -> NSTableRowView? {
        LineNumberTableRowView()
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? FilesTableView else {
            return
        }
        updateDetailLines(tableView.selectedRow)

        let visibleRows = tableView.rows(in: tableView.visibleRect)

        for row in visibleRows.location ..< NSMaxRange(visibleRows) {
            if let cellView = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? LineNumberTableCellView {
                cellView.isSelected = tableView.isRowSelected(row)
            }
        }
    }

    // MARK: - Drag&Drop

    public func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow _: Int, proposedDropOperation _: NSTableView.DropOperation) -> NSDragOperation {
        let pasteboard = info.draggingPasteboard

        var result: NSDragOperation = []

        tableView.setDropRow(-1, dropOperation: .on)
        if pasteboard.availableType(from: [.fileURL]) == nil {
            return result
        }
        guard let arr = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return result
        }

        let path1 = arr[0].osPath
        var isDir = ObjCBool(false)
        let isValidPath1 = FileManager.default.fileExists(atPath: path1, isDirectory: &isDir) && isDir.boolValue == false

        if arr.count < 2 {
            if isValidPath1 {
                result = .copy
            }
        } else {
            let path2 = arr[1].osPath
            let isValidPath2 = FileManager.default.fileExists(atPath: path2, isDirectory: &isDir) && isDir.boolValue == false
            if isValidPath1, isValidPath2 {
                result = .copy
            }
        }

        return result
    }

    public func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row _: Int, dropOperation _: NSTableView.DropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard
        if pasteboard.availableType(from: [.fileURL]) == nil {
            return false
        }
        guard let arr = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return false
        }

        if arr.count < 2 {
            guard let path = arr.last?.osPath else {
                return false
            }
            if tableView === leftView {
                sessionDiff.leftPath = path
            } else {
                sessionDiff.rightPath = path
            }
        } else {
            sessionDiff.leftPath = arr[0].osPath
            sessionDiff.rightPath = arr[1].osPath
        }

        reloadAllMove(toFirstDifference: false)

        return true
    }

    func tableView(_: NSTableView, menuItem: NSMenuItem, hideMenuItem hide: inout Bool) -> Bool {
        let action = menuItem.action

        hide = true
        var isValid = false
        if action == #selector(showInFinder) {
            isValid = true
        } else if action == #selector(copyFullPaths)
            || action == #selector(copyFileNames) {
            isValid = true
        } else if action == #selector(showWhitespaces) {
            if self.scopeBar.showWhitespaces {
                menuItem.title = NSLocalizedString("Hide Whitespaces", comment: "")
            } else {
                menuItem.title = NSLocalizedString("Show Whitespaces", comment: "")
            }

            isValid = true
        } else if action == #selector(popupOpenWithApp) {
            // validateMenuItem fills the menu
            return validateMenuItem(menuItem)
        } else if action == #selector(selectSection) {
            isValid = true
        } else if action == #selector(selectAdjacentSections) {
            isValid = true
        } else if action == #selector(copyLines) {
            if lastUsedView.side == .left {
                isValid = !sessionDiff.rightReadOnly
            } else {
                isValid = !sessionDiff.leftReadOnly
            }
            hide = !isValid
        } else if action == #selector(deleteLines) {
            isValid = validateMenuItem(menuItem)
        } else if action == #selector(saveFile) {
            isValid = lastUsedView.isDirty
        } else if action == #selector(toggleDetails) {
            isValid = true
        }

        return isValid
    }

    // MARK: - FilesTableViewDelegate methods

    func setLastUsedViewResponder(_ view: FilesTableView) {
        lastUsedView = view

        guard let items = window?.toolbar?.visibleItems else {
            return
        }
        for item in items {
            updateToolbarButton(item)
        }
    }

    func filesTableView(_: FilesTableView, doubleClick _: Int) {
        if let event = NSApp.currentEvent,
           event.modifierFlags.contains(.shift) {
            selectAdjacentSections(nil)
        } else {
            selectSection(nil)
        }
    }

    func filesTableView(_: FilesTableView, scrollHorizontally leftScroll: Bool) {
        let columnSlider = leftPanelView.columnSlider

        columnSlider.doubleValue += leftScroll ? -1 : 1
        sliderMoved(columnSlider)
    }

    func deleteKeyPressed(_: FilesTableView) {
        deleteLines(nil)
    }

    func formattedText(_ diffLine: DiffLine) -> String {
        let startingColumn = leftPanelView.columnSlider.integerValue
        let line = getLine(diffLine)

        if line.count < startingColumn {
            return "\u{27a5}"
        }
        if startingColumn > 0 {
            let index = line.index(line.startIndex, offsetBy: startingColumn)
            return String(line[index ..< line.endIndex])
        }

        return line
    }
}
