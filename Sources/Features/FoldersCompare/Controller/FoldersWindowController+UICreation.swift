//
//  FoldersWindowController+UICreation.swift
//  VisualDiffer
//
//  Created by davide ficano on 04/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

// height given to the preview pane until the user resizes it
private let previewPaneDefaultHeight: CGFloat = 200.0

// the panels are laid out by nested split views, so their frame is still the seed one when the
// constraints are first evaluated: every pane the seed gets divided into must clear the panel
// minimum content height, 40, or that first pass is unsatisfiable and AppKit logs a conflict.
// the value never reaches the screen, from the first layout on the size comes from the window
private let folderPanelsSeedHeight: CGFloat = 400.0

extension FoldersWindowController {
    func createFolderPanelsSplitView() -> NSSplitView {
        let view = NSSplitView(frame: NSRect(x: 0, y: 0, width: 1, height: folderPanelsSeedHeight))

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

        return view
    }

    func createConsoleView() -> ConsoleView {
        let view = ConsoleView(frame: NSRect(x: 0, y: 0, width: 1, height: 0))
        view.delegate = self

        return view
    }

    func createConsoleSplitter() -> DualPaneSplitView {
        let view = DualPaneSplitView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    func createPreviewSplitter(panel: FolderPanelView, preview: FilePreviewView) -> DualPaneSplitView {
        // the two splitters are laid out side by side, a zero width makes the parent
        // split view divide by zero and give the whole width to the first one
        let view = DualPaneSplitView(frame: NSRect(x: 0, y: 0, width: 1, height: 0))

        // the panel and the preview share the same background, the thin style would hide the divider
        view.dividerStyle = .paneSplitter
        view.collapsablePaneSize = previewPaneDefaultHeight
        view.addArrangedSubview(panel)
        view.addArrangedSubview(preview)

        return view
    }
}
