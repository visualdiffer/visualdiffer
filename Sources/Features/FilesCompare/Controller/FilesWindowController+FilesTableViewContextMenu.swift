//
//  FilesWindowController+FilesTableViewContextMenu.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

@MainActor
extension FilesWindowController: @preconcurrency FilesTableViewContextMenu {
    @objc
    func copyFileNames(_: AnyObject?) {
        if let path = lastUsedView.side == .left ? sessionDiff.leftPath : sessionDiff.rightPath {
            let url = URL(filePath: path, directoryHint: .notDirectory)

            NSPasteboard.general.copy(lines: [url.lastPathComponent])
        }
    }

    @objc
    func copyFullPaths(_: AnyObject?) {
        if let path = lastUsedView.side == .left ? sessionDiff.leftPath : sessionDiff.rightPath {
            NSPasteboard.general.copy(lines: [path])
        }
    }

    @objc
    func showWhitespaces(_ sender: AnyObject?) {
        cachedLineTextMap.removeAllObjects()

        // the scopeBar button toggles automatically but when this method is called
        // from the menu we set it manually
        if sender !== scopeBar {
            scopeBar.showWhitespaces(!scopeBar.showWhitespaces, informDelegate: false)
        }
        updateDetailLines(leftView.selectedRow)

        leftView.reloadData(restoreSelection: true)
        rightView.reloadData(restoreSelection: true)
    }

    @objc
    func showInFinder(_: AnyObject?) {
        guard let path = lastUsedView.side == .left ? sessionDiff.leftPath : sessionDiff.rightPath else {
            return
        }
        NSWorkspace.shared.show(inFinder: [path])
    }

    @objc
    func openWithApp(_ sender: AnyObject?) {
        guard let app = sender?.representedObject as? String,
              let editorData = lastUsedView.editorData(sessionDiff) else {
            return
        }
        openWith(app: URL(filePath: app), attributes: [editorData])
    }

    @objc
    func popupOpenWithApp(_: AnyObject?) {
        // Make happy Cocoa otherwise without action the menuitem is always grayed
    }

    @objc
    func openWithOther(_: AnyObject) {
        guard let editorData = lastUsedView.editorData(sessionDiff) else {
            return
        }
        openWithOtherApp(editorData)
    }

    @objc
    func copyLines(_: AnyObject?) {
        let selectedRows = lastUsedView.selectedRowIndexes

        guard !selectedRows.isEmpty,
              let diffResult,
              let currentDiffResult,
              let linkedView = lastUsedView.linkedView else {
            return
        }

        DiffResult.copyLines(
            all: diffResult,
            current: currentDiffResult,
            rows: selectedRows,
            source: lastUsedView.side,
            visibility: scopeBar.showLinesFilter == .differences ? .differences : .all
        )

        linkedView.isDirty = true
        refreshAfterTextEdit()
    }

    @objc
    func deleteLines(_: AnyObject?) {
        let selectedRows = lastUsedView.selectedRowIndexes

        guard !selectedRows.isEmpty,
              let diffResult,
              let currentDiffResult else {
            return
        }

        DiffResult.deleteLines(
            all: diffResult,
            current: currentDiffResult,
            rows: selectedRows,
            side: lastUsedView.side,
            visibility: scopeBar.showLinesFilter
        )

        lastUsedView.isDirty = true
        refreshAfterTextEdit()
    }

    @objc
    func selectSection(_: AnyObject?) {
        guard let indexes = currentDiffResult?.findSectionIndexSet(with: lastUsedView.selectedRow) else {
            return
        }
        lastUsedView.selectRowIndexes(indexes, byExtendingSelection: false)
    }

    @objc
    func selectAdjacentSections(_: AnyObject?) {
        guard let indexes = currentDiffResult?.findAdjacentSections(from: lastUsedView.selectedRow) else {
            return
        }

        lastUsedView.selectRowIndexes(indexes, byExtendingSelection: false)
    }

    @objc
    func saveFile(_ sender: AnyObject?) {
        let view = if sender === leftPanelView.pathView.saveButton {
            leftView
        } else if sender === rightPanelView.pathView.saveButton {
            rightView
        } else {
            lastUsedView
        }
        if view.isDirty {
            do {
                try saveView(view)
                // remove mode
                if let diffSide = view.diffSide {
                    for line in diffSide.lines {
                        line.mode = .normal
                    }
                }
                view.reloadData()
                updateDetailLines(lastUsedView.selectedRow)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    // MARK: - Open with external applications

    func openWith(
        app: URL,
        attributes: [OpenEditorAttribute]
    ) {
        let editor = OpenEditor(attributes: attributes)
        do {
            try editor.open(withApplication: app)
        } catch let error as NSError {
            if let window {
                NSAlert(error: error).beginSheetModal(for: window)
            }
        }
    }

    func openWithOtherApp(_ attributes: OpenEditorAttribute) {
        let editor = OpenEditor(attributes: attributes)

        do {
            try editor.browseApplicationAndLaunch()
        } catch let error as NSError {
            if let window {
                NSAlert(error: error).beginSheetModal(for: window)
            }
        }
    }

    @objc
    func copyLinesToLeft(_ sender: AnyObject?) {
        if lastUsedView.side == .right {
            copyLines(sender)
        }
    }

    @objc
    func copyLinesToRight(_ sender: AnyObject?) {
        if lastUsedView.side == .left {
            copyLines(sender)
        }
    }
}
