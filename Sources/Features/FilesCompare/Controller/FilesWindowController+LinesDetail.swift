//
//  FilesWindowController+LinesDetail.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController: NSTextViewDelegate {
    @objc
    func toggleDetails(_: AnyObject) {
        let isHidden = !linesDetailView.isHidden
        linesDetailView.isHidden = isHidden
        CommonPrefs.shared.hideFileDiffDetails = isHidden
    }

    public func textView(_ textView: NSTextView, menu: NSMenu, for _: NSEvent, at _: Int) -> NSMenu? {
        if textView === leftDetailsTextView || textView === rightDetailsTextView {
            // Add items to NSTextField context menu
            menu.insertItem(
                NSMenuItem.separator(),
                at: 0
            )
            menu.insertItem(
                withTitle: NSLocalizedString("Hide Details", comment: ""),
                action: #selector(toggleDetails),
                keyEquivalent: "",
                at: 0
            )
        }
        return menu
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if textView === leftDetailsTextView || textView === rightDetailsTextView {
            // let the window determine what to do, close window when ESC is pressed or ignore the command
            if commandSelector == #selector(cancelOperation) {
                window?.cancelOperation(textView)
                return true
            }
        }
        return false
    }
}
