//
//  FilePanelView.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FilePanelView: TablePanelView<FilesTableView, FileInfoBar> {
    private var sliderPosition: NSLayoutConstraint?

    lazy var columnSlider: NSSlider = createSlider()
    var fileInfoBar: FileInfoBar

    var isDirty: Bool {
        get {
            treeView.isDirty
        }
        set {
            treeView.isDirty = newValue
        }
    }

    var isEditAllowed: Bool {
        get {
            treeView.isEditAllowed
        }
        set {
            treeView.isEditAllowed = newValue
        }
    }

    init(side: DisplaySide) {
        fileInfoBar = Self.createFileInfoBar()
        super.init(treeView: FilesTableView(frame: .zero), bottomBar: fileInfoBar)
        self.side = side
    }

    private static func createFileInfoBar() -> FileInfoBar {
        let view = FileInfoBar(frame: .zero)

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func createSlider() -> NSSlider {
        let view = NSSlider(frame: .zero)

        view.toolTip = NSLocalizedString("Horizontal synchronized scroll", comment: "")
        view.sliderType = .linear
        view.tickMarkPosition = .above
        view.minValue = 0
        view.maxValue = 100
        view.controlSize = .small
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    override func addSubviews() {
        super.addSubviews()

        // fileInfoBar is added as bottomBar inside super.addSubviews
        addSubview(columnSlider)
    }

    override func setupBottomBarConstraints() {
        let constraints = columnSlider.leadingAnchor.constraint(equalTo: leadingAnchor)
        sliderPosition = constraints

        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: columnSlider.topAnchor),

            constraints,
            columnSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            columnSlider.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func alignSlider(width textX: CGFloat) {
        sliderPosition?.constant = textX
    }

    func setSliderMaxValue(_ left: [DiffLine], right: [DiffLine]) {
        var maxColumn = 0

        for (index, line) in left.enumerated() {
            let tempMax = max(line.text.count, right[index].text.count)
            if tempMax > maxColumn {
                maxColumn = tempMax
            }
        }
        columnSlider.maxValue = Double(maxColumn)
    }

    func setSliderChangeAction(_ target: AnyObject?, action: Selector?) {
        columnSlider.target = target
        columnSlider.action = action
    }

    func setDelegate(_ delegate: PathControlDelegate
        & FilesTableViewDelegate
        & FileInfoBarDelegate
        & NSTableViewDataSource) {
        pathViewDelegate = delegate

        treeView.delegate = delegate
        treeView.dataSource = delegate

        fileInfoBar.delegate = delegate
    }

    /**
     * If word wrap is enabled calling reloadData() can cause the rows to be not visible
     * until table is resized or mouse is dragged, calling this method the rows are updated correctly
     */
    func reloadTreeData() {
        guard let scrollView = treeView.enclosingScrollView else {
            treeView.reloadData()
            return
        }

        let savedOrigin = scrollView.documentVisibleRect.origin

        let all = IndexSet(integersIn: 0 ..< treeView.numberOfRows)
        treeView.noteHeightOfRows(withIndexesChanged: all)

        treeView.reloadData(restoreSelection: true)
        treeView.layoutSubtreeIfNeeded()

        treeView.scroll(savedOrigin)

        treeView.setNeedsDisplay(treeView.bounds)
    }
}
