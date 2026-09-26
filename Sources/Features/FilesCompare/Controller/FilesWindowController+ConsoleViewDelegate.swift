//
//  FilesWindowController+ConsoleViewDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/09/26
//  Copyright (c) 2026 visualdiffer.com
//

extension FilesWindowController: ConsoleDisplayable {
    var consoleFocusView: NSView {
        lastUsedView
    }

    // a menu item needs a real selector, a protocol extension cannot provide one
    @objc
    func toggleLogConsole(_: AnyObject?) {
        hide(console: consoleView)
    }
}
