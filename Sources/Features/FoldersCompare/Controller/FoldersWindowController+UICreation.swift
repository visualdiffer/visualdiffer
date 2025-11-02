//
//  FoldersWindowController+UICreation.swift
//  VisualDiffer
//
//  Created by davide ficano on 04/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController {
    func createFolderPanelsSplitView() -> NSSplitView {
        let view = NSSplitView(frame: NSRect(x: 0, y: 0, width: 1, height: 0))

        view.dividerStyle = .thin
        view.isVertical = true

        return view
    }

    func createProgressView() -> ProgressBarView {
        let view = ProgressBarView(frame: .zero)
        view.setStop(action: #selector(stopRefresh), target: self)

        return view
    }

    func createStatusbar() -> NSStackView {
        let spacerView = NSView()
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        spacerView.setContentHuggingPriority(.init(1), for: .horizontal)

        let spacerWidth = spacerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)
        spacerWidth.priority = .defaultLow
        spacerWidth.isActive = true

        differenceCounters.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        progressView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let view = NSStackView(views: [
            differenceCounters,
            progressView,
            spacerView,
            statusbarText,
        ])

        view.orientation = .horizontal
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .centerY
        view.distribution = .fill
        view.spacing = 10

        return view
    }

    func createStatusbarText() -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.drawsBackground = false
        view.isBezeled = false
        view.isBordered = false
        view.isEditable = false
        view.textColor = NSColor.controlTextColor
        view.backgroundColor = NSColor.controlColor
        view.controlSize = .small
        view.alignment = .right
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    func createDisplayFiltersScopeBar() -> DisplayFiltersScopeBar {
        let view = DisplayFiltersScopeBar(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.initScopeBar(self)
        view.reloadData()

        return view
    }

    func createConsoleView() -> ConsoleView {
        let view = ConsoleView(frame: NSRect(x: 0, y: 0, width: 1, height: 0))
        view.delegate = self

        return view
    }

    func createConsoleSplitter() -> DualPaneSplitView {
        let frame = window?.contentView?.bounds ?? .zero
        let view = DualPaneSplitView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.firstViewSize = frame.height * 3 / 4

        return view
    }
}
