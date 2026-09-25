//
//  FolderPanelView.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

private let bottomBarInset: CGFloat = 3

class FolderPanelView: TablePanelView<FoldersOutlineView, NSTextField> {
    override var pathViewDelegate: PathControlDelegate? {
        willSet {
            pathView.isSaveHidden = true
        }
    }

    init() {
        super.init(treeView: FoldersOutlineView(frame: .zero), bottomBar: NSTextField.hintWithTitle(""))
        treeView.addColumns()
    }

    override func setupBottomBarConstraints() {
        // no super: it pins the scroll view straight to bottomBar.top, leaving no room for the inset
        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -bottomBarInset),
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomBarInset),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -bottomBarInset),
            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: bottomBarInset),
        ])
    }

    override func setupBottomBar() {
        bottomBar.alignment = .center
        bottomBar.lineBreakMode = .byClipping
    }

    override func updateBottomBar() {
        bottomBar.stringValue = treeView.getFileCountInfo().description
    }

    static func createFolderPanel(
        side: DisplaySide,
        delegate: PathControlDelegate & FoldersOutlineViewDelegate & NSOutlineViewDataSource
    ) -> FolderPanelView {
        let view = FolderPanelView()
        view.pathViewDelegate = delegate
        view.side = side

        view.treeView.delegate = delegate
        view.treeView.dataSource = delegate
        view.treeView.setupColumnsSort()

        return view
    }
}
