//
//  FilesWindowController.swift
//  VisualDiffer
//
//  Created by davide ficano on 20/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

@objc class FilesWindowController: NSWindowController {
    // swiftlint:disable:next implicitly_unwrapped_optional
    @objc var sessionDiff: SessionDiff!

    let cachedLineTextMap: NSMapTable<DiffLine, NSString>

    var currentFont: NSFont
    var fontZoomFactor: CGFloat = 0 {
        didSet {
            if fontZoomFactor < 0 || fontZoomFactor > 10 {
                fontZoomFactor = oldValue
            }
            updateUI()
        }
    }

    lazy var differenceCounters: DifferenceCounters = createDifferenceCounters()
    lazy var statusbarText: NSTextField = createStatusbarText()

    lazy var fileThumbnail: FileThumbnailView = createThumbnailView()

    let visibleWhitespaces: VisibleWhitespaces

    lazy var scopeBar: FilesScopeBar = createFilesScopeBar()
    var lastUsedView: FilesTableView

    var diffResult: DiffResult?
    var filteredDiffResult: DiffResult?
    var currentDiffResult: DiffResult?

    var resolvedLeftPath: URL?
    var resolvedRightPath: URL?

    lazy var linesDetailView: NSView = createLinesDetailViewWith()
    lazy var leftDetailsTextView: NSTextView = createLineDetailTextView()
    lazy var rightDetailsTextView: NSTextView = createLineDetailTextView()

    lazy var topBottomView: WindowOSD = .init(
        // swiftlint:disable:next force_unwrapping
        image: NSImage(named: VDImageNameBottom)!,
        parent: window
    )

    let filePanels: NSSplitView
    let leftPanelView: FilePanelView
    let rightPanelView: FilePanelView

    @objc var leftView: FilesTableView {
        leftPanelView.treeView
    }

    @objc var rightView: FilesTableView {
        rightPanelView.treeView
    }

    init() {
        let window = WindowCancelOperation.createWindow()

        currentFont = CommonPrefs.shared.fileTextFont

        visibleWhitespaces = VisibleWhitespaces()
        visibleWhitespaces.tabWidth = CommonPrefs.shared.tabWidth

        cachedLineTextMap = NSMapTable<DiffLine, NSString>(
            keyOptions: .objectPointerPersonality,
            valueOptions: .strongMemory
        )

        // panels
        leftPanelView = FilePanelView(side: .left)
        rightPanelView = FilePanelView(side: .right)
        filePanels = Self.createFilePanelsSplitView(
            leftPanelView: leftPanelView,
            rightPanelView: rightPanelView
        )

        lastUsedView = leftPanelView.treeView

        super.init(window: window)

        setup(
            filePanel: leftPanelView,
            delegate: self,
            sliderTarget: self,
            sliderAction: #selector(sliderMoved)
        )
        setup(
            filePanel: rightPanelView,
            delegate: self,
            sliderTarget: self,
            sliderAction: #selector(sliderMoved)
        )

        shouldCascadeWindows = false

        initAllViews()
    }

    func setup(
        filePanel: FilePanelView,
        delegate: PathControlDelegate & FilesTableViewDelegate & FileInfoBarDelegate & NSTableViewDataSource,
        sliderTarget target: AnyObject?,
        sliderAction action: Selector?
    ) {
        filePanel.setDelegate(delegate)
        filePanel.setSliderChangeAction(target, action: action)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Zoom Font

    @objc func zoomLargerFont(_: AnyObject) {
        fontZoomFactor += 1
    }

    @objc func zoomSmallerFont(_: AnyObject) {
        fontZoomFactor -= 1
    }

    @objc func zoomResetFont(_: AnyObject) {
        fontZoomFactor = 0
    }
}
