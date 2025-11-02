//
//  TablePanelView.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class TablePanelView<T: NSTableView & DisplayPositionable & ViewLinkable<T>, BottomBarView: NSView>: NSView {
    var side: DisplaySide = .left {
        didSet {
            treeView.side = side
        }
    }

    var treeView: T
    var scrollView: SynchroScrollView
    var bottomBar: BottomBarView
    var pathView: PathView

    init(
        treeView: T,
        bottomBar: BottomBarView
    ) {
        self.treeView = treeView
        self.bottomBar = bottomBar
        scrollView = Self.createScrollView()
        pathView = Self.createPathView()

        super.init(frame: NSRect(x: 0, y: 0, width: 1, height: 0))

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        setupScrollView()
        setupBottomBar()

        addSubviews()

        setupConstraints()
    }

    func addSubviews() {
        addSubview(pathView)
        addSubview(scrollView)
        addSubview(bottomBar)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            pathView.topAnchor.constraint(equalTo: topAnchor),
            pathView.heightAnchor.constraint(equalToConstant: 18),
            pathView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pathView.leadingAnchor.constraint(equalTo: leadingAnchor),

            scrollView.topAnchor.constraint(equalTo: pathView.bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])

        setupBottomBarConstraints()
    }

    func setupBottomBarConstraints() {
        scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor).isActive = true
    }

    static func createPathView() -> PathView {
        let view = PathView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    static func createScrollView() -> SynchroScrollView {
        let view = SynchroScrollView(frame: .zero)

        view.borderType = .noBorder
        view.autohidesScrollers = true
        view.hasHorizontalScroller = true
        view.hasVerticalScroller = true
        view.horizontalLineScroll = 19
        view.horizontalPageScroll = 10
        view.verticalLineScroll = 19
        view.verticalPageScroll = 10
        view.usesPredominantAxisScrolling = false
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    func setupScrollView() {
        scrollView.documentView = treeView
    }

    func setupTreeView() {}

    func setupBottomBar() {}

    var pathViewDelegate: PathControlDelegate? {
        get { pathView.delegate }
        set { pathView.delegate = newValue }
    }

    func synchronizeWith(_ other: SynchroScrollView) {
        scrollView.setSynchronized(scrollview: other)
    }

    /**
     Link treeView with other.treeView and sync scrollViews
     self is linked to other and other is linked to self, too
     */
    func setLinkPanels(_ other: TablePanelView) {
        treeView.linkedView = other.treeView
        other.treeView.linkedView = treeView

        synchronizeWith(other.scrollView)
        other.synchronizeWith(scrollView)
    }

    func bindControls() {
        pathView.bindControls(side: side)
    }

    func updateBottomBar() {}
}
