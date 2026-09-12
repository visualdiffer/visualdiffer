//
//  FilesWindowController+UICreation.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

// the stack view is a pane of the console splitter, so its frame is still the seed one when
// the constraints are first evaluated and it must already clear the height its content needs,
// or that first pass is unsatisfiable and causes AppKit to log a conflict
private let detailsStackSeedHeight: CGFloat = 400.0

extension FilesWindowController {
    func createDifferenceCounters() -> DifferenceCounters {
        let view = DifferenceCounters(frame: .zero)

        view.isHidden = false
        view.translatesAutoresizingMaskIntoConstraints = false

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

    func createLinesDetailViewWith() -> NSView {
        let leftScrollView = createLineDetailScrollViewWithDocumentView(leftDetailsTextView)
        let rightScrollView = createLineDetailScrollViewWithDocumentView(rightDetailsTextView)

        let linesDetailView = NSView(frame: .zero)
        linesDetailView.translatesAutoresizingMaskIntoConstraints = false

        linesDetailView.addSubview(leftScrollView)
        linesDetailView.addSubview(rightScrollView)

        NSLayoutConstraint.activate([
            leftScrollView.leadingAnchor.constraint(equalTo: linesDetailView.leadingAnchor),
            leftScrollView.trailingAnchor.constraint(equalTo: linesDetailView.trailingAnchor),
            leftScrollView.topAnchor.constraint(equalTo: linesDetailView.topAnchor),
            leftScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 22),

            rightScrollView.leadingAnchor.constraint(equalTo: linesDetailView.leadingAnchor),
            rightScrollView.trailingAnchor.constraint(equalTo: linesDetailView.trailingAnchor),
            rightScrollView.topAnchor.constraint(equalTo: leftScrollView.bottomAnchor, constant: 1),
            rightScrollView.bottomAnchor.constraint(equalTo: linesDetailView.bottomAnchor),
            rightScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 22),
        ])

        return linesDetailView
    }

    func createLineDetailScrollViewWithDocumentView(_ documentView: NSView) -> NSScrollView {
        let view = NSScrollView(frame: .zero)

        view.hasVerticalScroller = false
        view.hasHorizontalScroller = false
        view.documentView = documentView
        view.borderType = .bezelBorder
        view.translatesAutoresizingMaskIntoConstraints = false
        view.drawsBackground = false

        return view
    }

    func createLineDetailTextView() -> LineDetailTextView {
        let view = LineDetailTextView()

        view.isSelectable = true
        view.isEditable = false
        view.isRichText = true
        view.disableWordWrap()
        view.textContainerInset = NSSize(width: 0, height: 0)
        view.textContainer?.lineFragmentPadding = 0

        view.delegate = self
        view.drawsBackground = false
        view.font = currentFont

        return view
    }

    func createFilesScopeBar() -> FilesScopeBar {
        let view = FilesScopeBar(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.initScopeBar(self)

        return view
    }

    func createThumbnailView() -> FileThumbnailView {
        let view = FileThumbnailView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    func createLineDetailsStackWithViews(_ views: [NSView]) -> NSStackView {
        let view = NSStackView(views: views)

        view.frame = NSRect(x: 0, y: 0, width: 1, height: detailsStackSeedHeight)
        view.orientation = .vertical
        view.alignment = .width
        view.distribution = .fill

        return view
    }

    static func createFilePanelsWithFrame(_ frame: NSRect) -> NSSplitView {
        let view = NSSplitView(frame: frame)

        view.dividerStyle = .thin
        view.isVertical = true
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    static func createFilePanelsSplitView(
        leftPanelView: FilePanelView,
        rightPanelView: FilePanelView
    ) -> NSSplitView {
        let filePanels = createFilePanelsWithFrame(NSRect(x: 0, y: 0, width: 1, height: 0))

        filePanels.addArrangedSubview(leftPanelView)
        filePanels.addArrangedSubview(rightPanelView)

        leftPanelView.setLinkPanels(rightPanelView)

        return filePanels
    }

    /**
     * The view on top of screen, it contains the thumbnail on the left and file difference panels on the right
     */
    func createTopView(_ leftView: NSView, rightView: NSView) -> NSView {
        let topView = NSView(frame: .zero)

        topView.addSubview(leftView)
        topView.addSubview(rightView)

        NSLayoutConstraint.activate([
            leftView.leadingAnchor.constraint(equalTo: topView.leadingAnchor),
            leftView.topAnchor.constraint(equalTo: topView.topAnchor, constant: 18),
            leftView.bottomAnchor.constraint(equalTo: topView.bottomAnchor),
            leftView.widthAnchor.constraint(equalToConstant: 15),

            rightView.leadingAnchor.constraint(equalTo: leftView.trailingAnchor),
            rightView.trailingAnchor.constraint(equalTo: topView.trailingAnchor),
            rightView.topAnchor.constraint(equalTo: topView.topAnchor),
            rightView.bottomAnchor.constraint(equalTo: topView.bottomAnchor),
        ])

        return topView
    }

    func createProgressView() -> ProgressBarView {
        let view = ProgressBarView(frame: .zero)

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }
}
