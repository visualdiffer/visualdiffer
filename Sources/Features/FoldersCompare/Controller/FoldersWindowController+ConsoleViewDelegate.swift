//
//  FoldersWindowController+ConsoleViewDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController: @preconcurrency ConsoleViewDelegate {
    // MARK: - Delegate

    func hide(console _: ConsoleView) {
        if consoleSplitter.hasSubviewCollapsed {
            showConsoleView()
        } else {
            hideConsoleView()
        }
    }

    // MARK: - ConsoleSplitView

    func log(error: String) {
        showConsoleView()
        consoleView.log(error: error)
    }

    func showConsoleView() {
        consoleSplitter.expandSubview()
        consoleView.focus()
    }

    func hideConsoleView() {
        consoleSplitter.collapseSubview()
        // focus lost on console hide, AppKit leaves the first responder on the
        // hidden text view and the window moves it to the toolbar
        window?.makeFirstResponder(lastUsedView)
    }

    @objc
    func toggleLogConsole(_: AnyObject?) {
        hide(console: consoleView)
    }
}
