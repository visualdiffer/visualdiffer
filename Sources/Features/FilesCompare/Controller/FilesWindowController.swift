//
//  FilesWindowController.swift
//  VisualDiffer
//
//  Created by davide ficano on 20/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

// minimum heights of the two panes of the console splitter
private let filePanelsMinHeight: CGFloat = 160.0
private let consoleMinHeight: CGFloat = 80.0

class FilesWindowController: NSWindowController {
    var lineNumberWidth: CGFloat = 0

    var rowHeightCalculator = RowHeightCalculator()

    // swiftlint:disable:next implicitly_unwrapped_optional
    @objc var sessionDiff: SessionDiff!

    // keyed by line identity, the dictionary keeps the lines alive as long as they are cached
    var cachedLineTextMap = [DiffLine: String]()

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
    lazy var progressView: ProgressBarView = createProgressView()

    lazy var fileThumbnail: FileThumbnailView = createThumbnailView()

    let visibleWhitespaces: VisibleWhitespaces

    lazy var scopeBar: FilesScopeBar = createFilesScopeBar()
    var lastUsedView: FilesTableView

    var diffResult: DiffResult?
    var filteredDiffResult: DiffResult?
    var currentDiffResult: DiffResult?

    // the comparison runs detached, a new one is refused until it completes
    var isComparing = false

    // set when a comparison starts, the console reports how long it took
    var comparisonStartedAt = Date()

    // a reload asked while a comparison runs, it carries what that request still owes
    struct PendingReload {
        var toFirstDifference = false
        var statusMessage: String?
    }

    var pendingReload: PendingReload?

    // a detached comparison outlives the window, the session it reads does not
    var isClosed = false

    // restores the counters once a status bar message has been read, a newer message
    // replaces the pending one
    var statusMessageTask: Task<Void, Never>?

    var resolvedLeftPath: URL?
    var resolvedRightPath: URL?

    lazy var linesDetailView = createLinesDetailViewWith()
    lazy var leftDetailsTextView = createLineDetailTextView()
    lazy var rightDetailsTextView = createLineDetailTextView()

    lazy var topBottomView: WindowOSD = .init(
        image: VDSymbol.Asset.bottom.image(),
        parent: window
    )

    // the console is the bottom pane of the window, collapsed until an error is logged
    // or the user asks for it
    lazy var consoleSplitter: DualPaneSplitView = {
        let view = createConsoleSplitter()

        view.addArrangedSubview(detailsStackView)
        view.addArrangedSubview(consoleView)

        return view
    }()

    lazy var consoleView: ConsoleView = createConsoleView()

    lazy var detailsStackView: NSStackView = createLineDetailsStackWithViews([
        createTopView(fileThumbnail, rightView: filePanels),
        linesDetailView,
    ])

    var consoleDelegate = DualPaneSplitViewDelegate(
        collapsableSubViewIndex: 1,
        minFirstPaneSize: filePanelsMinHeight,
        minSecondPaneSize: consoleMinHeight
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

    var preferences = FilePreferences()

    lazy var sessionPreferencesSheet: FileSessionPreferencesWindow = .init()

    // the folder session the compared files were opened from, nil for a standalone window
    var parentSession: DiffOpenerDelegate? {
        (document as? VDDocument)?.parentSession
    }

    init() {
        let window = WindowCancelOperation.createWindow()

        currentFont = CommonPrefs.shared.fileTextFont

        visibleWhitespaces = VisibleWhitespaces()
        visibleWhitespaces.tabWidth = CommonPrefs.shared.tabWidth

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

        filePanels.delegate = self

        setupHeightSynchronizer()
        setWordWrap(enabled: false)
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

    @available(*, unavailable, message: "use init()")
    required init?(coder _: NSCoder) {
        nil
    }

    // MARK: - Zoom Font

    @objc
    func zoomLargerFont(_: AnyObject) {
        fontZoomFactor += 1
    }

    @objc
    func zoomSmallerFont(_: AnyObject) {
        fontZoomFactor -= 1
    }

    @objc
    func zoomResetFont(_: AnyObject) {
        fontZoomFactor = 0
    }
}
