//
//  FoldersWindowController+ConsoleViewDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController: @preconcurrency ConsoleViewDelegate {
    // MARK: - Delegate

    func hide(console: ConsoleView) {
        consoleSplitter.toggleSubview(at: 1)
        console.focus()
    }

    // MARK: - ConsoleSplitView

    func log(error: String) {
        showConsoleView()
        consoleView.log(error: error)
    }

    func showConsoleView() {
        consoleSplitter.expandSubview(at: 1)
        consoleView.focus()
    }

    @objc func toggleLogConsole(_: AnyObject?) {
        hide(console: consoleView)
    }
}
