//
//  FilesWindowController+Clipboard.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

@MainActor extension FilesWindowController {
    @objc func copyUrlsToClipboard(_: AnyObject) {
        if let path = lastUsedView.side == .left ? sessionDiff.leftPath : sessionDiff.rightPath {
            let url = URL(filePath: path, directoryHint: .notDirectory)

            NSPasteboard.general.copy(urls: [url])
        }
    }

    @objc func copy(_ sender: AnyObject) {
        copyLinesToClipboard(sender)
    }

    @objc func copyLinesToClipboard(_: AnyObject) {
        guard let diffSide = lastUsedView.diffSide else {
            return
        }
        let selectedRows = lastUsedView.selectedRowIndexes
        let arr = diffSide.lines
        var lines = selectedRows.map { arr[$0].text }

        // add an empty line
        lines.append("")
        NSPasteboard.general.copy(lines: lines)
    }

    @objc func paste(_ sender: AnyObject) {
        pasteLinesToClipboard(sender)
    }

    @objc func pasteLinesToClipboard(_: AnyObject) {
        guard let diffResult else {
            return
        }
        let row = lastUsedView.selectedRow

        if row < 0 {
            return
        }

        let pasteboard = NSPasteboard.general
        let supportedTypes = [NSPasteboard.PasteboardType.string]
        guard pasteboard.availableType(from: supportedTypes) != nil,
              let text = pasteboard.string(forType: .string) else {
            return
        }

        diffResult.insert(
            text: text,
            at: row,
            side: lastUsedView.side
        )
        lastUsedView.isDirty = true
        refreshAfterTextEdit()
    }

    @objc func cut(_ sender: AnyObject) {
        cutToClipboard(sender)
    }

    @objc func cutToClipboard(_ sender: AnyObject) {
        copyLinesToClipboard(sender)
        deleteLines(sender)
    }
}
