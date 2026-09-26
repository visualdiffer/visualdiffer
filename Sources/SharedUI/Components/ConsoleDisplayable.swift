//
//  ConsoleDisplayable.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/09/26.
//  Copyright (c) 2026 visualdiffer.com
//

// the console pane is laid out by the splitter, so its frame is still the seed one when the
// constraints are first evaluated and it must already clear the height its own content needs,
// or that first pass is unsatisfiable and causes AppKit to log a conflict
private let consoleSeedHeight: CGFloat = 120.0

// the log console pane, shared by the file and the folder window so the two cannot drift apart
@MainActor
protocol ConsoleDisplayable: ConsoleViewDelegate {
    var consoleView: ConsoleView { get }
    var consoleSplitter: DualPaneSplitView { get }
    var consoleDelegate: DualPaneSplitViewDelegate { get }
    var window: NSWindow? { get }

    // the console takes the focus when it opens, hiding it hands the focus back to this view
    var consoleFocusView: NSView { get }
}

extension ConsoleDisplayable {
    func createConsoleView() -> ConsoleView {
        let view = ConsoleView(frame: NSRect(x: 0, y: 0, width: 1, height: consoleSeedHeight))
        view.delegate = self

        return view
    }

    func createConsoleSplitter() -> DualPaneSplitView {
        let view = DualPaneSplitView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    func setupConsoleSplitter() {
        consoleSplitter.delegate = consoleDelegate
        consoleSplitter.collapseSubview()
    }

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

    func logComparisonCompleted(elapsedTimeText: String) {
        consoleView.log(info: String(format: NSLocalizedString("Comparison completed in %@", comment: ""), elapsedTimeText))
    }

    func showConsoleView() {
        consoleSplitter.expandSubview()
        consoleView.focus()
    }

    func hideConsoleView() {
        consoleSplitter.collapseSubview()
        // focus lost on console hide, AppKit leaves the first responder on the
        // hidden text view and the window moves it to the toolbar
        window?.makeFirstResponder(consoleFocusView)
    }
}
