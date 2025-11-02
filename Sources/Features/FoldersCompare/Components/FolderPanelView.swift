//
//  FolderPanelView.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FolderPanelView: TablePanelView<FoldersOutlineView, NSTextField> {
    override var pathViewDelegate: PathControlDelegate? {
        willSet {
            pathView.isSaveHidden = true
        }
    }

    init() {
        super.init(treeView: FoldersOutlineView(frame: .zero), bottomBar: NSTextField(frame: .zero))
        treeView.addColumns()
    }

    override func setupBottomBarConstraints() {
        super.setupBottomBarConstraints()

        NSLayoutConstraint.activate([
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 22),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])
    }

    override func setupBottomBar() {
        bottomBar.centerVertically()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        bottomBar.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
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
