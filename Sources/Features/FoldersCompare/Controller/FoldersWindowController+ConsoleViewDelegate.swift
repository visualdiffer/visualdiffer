//
//  FoldersWindowController+ConsoleViewDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController: ConsoleDisplayable {
    var consoleFocusView: NSView {
        lastUsedView
    }

    // a menu item needs a real selector, a protocol extension cannot provide one
    @objc
    func toggleLogConsole(_: AnyObject?) {
        hide(console: consoleView)
    }
}
