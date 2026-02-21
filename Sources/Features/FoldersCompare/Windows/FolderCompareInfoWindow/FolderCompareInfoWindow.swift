//
//  FolderCompareInfoWindow.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/02/12.
//  Copyright (c) 2012 visualdiffer.com
//

class FolderCompareInfoWindow: NSWindow, NSOutlineViewDataSource, NSOutlineViewDelegate {
    var leftRoot: CompareItem?
    var comparatorOptions: ComparatorOptions = []
    var selectedItems: [CompareItem]?

    private var compareItems: DescriptionOutlineNode?

    private lazy var scrollView: NSScrollView = {
        let view = NSScrollView(frame: .zero)

        view.borderType = .bezelBorder
        view.autohidesScrollers = true
        view.hasHorizontalScroller = true
        view.hasVerticalScroller = true
        view.horizontalLineScroll = 19
        view.horizontalPageScroll = 10
        view.verticalLineScroll = 19
        view.verticalPageScroll = 10
        view.usesPredominantAxisScrolling = false
        view.translatesAutoresizingMaskIntoConstraints = false

        view.documentView = outlineView

        return view
    }()

    private lazy var closeButton: NSButton = {
        let view = NSButton(frame: .zero)

        view.title = NSLocalizedString("Close", comment: "")
        view.setButtonType(.momentaryPushIn)

        view.isBordered = true
        view.state = .off
        view.bezelStyle = .flexiblePush
        view.imagePosition = .noImage
        view.alignment = .center
        view.keyEquivalent = "\u{1B}"
        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = self
        view.action = #selector(closeSheet)

        return view
    }()

    private lazy var outlineView: NSOutlineView = {
        let view = NSOutlineView(frame: .zero)

        view.controlSize = .small
        view.headerView = nil
        view.dataSource = self
        view.delegate = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(""))
        column.isEditable = false
        column.width = 180
        column.minWidth = 100
        column.maxWidth = 1000
        column.resizingMask = [.autoresizingMask, .userResizingMask]

        view.addTableColumn(column)

        return view
    }()

    static func createSheet() -> FolderCompareInfoWindow {
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]

        return FolderCompareInfoWindow(
            contentRect: NSRect(x: 0, y: 0, width: 485, height: 286),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
    }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        setupViews()
    }

    private func setupViews() {
        contentMinSize = NSSize(width: 300, height: 200)
        hasShadow = true
        isReleasedWhenClosed = true

        let title = createTitle()

        if let contentView {
            contentView.addSubview(title)
            contentView.addSubview(scrollView)
            contentView.addSubview(closeButton)
        }

        setupConstraints(title)
    }

    private func setupConstraints(_ title: NSView) {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 19),
            title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -19),
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -19),
            scrollView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 7),
            scrollView.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -14),

            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -19),
            closeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }

    private func createTitle() -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.stringValue = NSLocalizedString("Folder Compare Info", comment: "")
        view.isBordered = false
        view.isBezeled = false
        view.drawsBackground = false
        view.textColor = NSColor.controlTextColor
        view.backgroundColor = NSColor.controlColor
        view.font = NSFont.boldSystemFont(ofSize: 13)
        view.isEditable = false
        view.isSelectable = false
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    func beginSheetModal(for window: NSWindow) {
        let items = DescriptionOutlineNode(text: "", isContainer: true)
        let allNode = DescriptionOutlineNode(text: NSLocalizedString("From Root", comment: ""), isContainer: true)

        items.children.append(allNode)

        if let leftRoot,
           let leftPath = leftRoot.path,
           let rightRoot = leftRoot.linkedItem,
           let rightPath = rightRoot.path,
           let selectedItems {
            allNode.addCompareGroup(leftRoot: leftRoot, comparatorOptions: comparatorOptions)
            for item in selectedItems {
                if let path = item.path, item.isFolder, item.isValidFile {
                    let (isOnLeft, node) = relative(node: leftPath, rightPath: rightPath, for: path)

                    if let node {
                        items.children.append(node)
                        if let leftRoot = isOnLeft ? item : item.linkedItem {
                            node.addCompareGroup(leftRoot: leftRoot, comparatorOptions: comparatorOptions)
                        }
                    }
                }
            }

            compareItems = items

            outlineView.reloadData()
            for node in items.children {
                outlineView.expandItem(node)
            }
        }

        window.beginSheet(self)
    }

    private func relative(node leftPath: String, rightPath: String, for path: String) -> (Bool, DescriptionOutlineNode?) {
        var isOnLeft = true
        var relativePath = relative(path: leftPath, for: path)

        if relativePath == nil {
            relativePath = relative(path: rightPath, for: path)
            isOnLeft = false
        }
        if let relativePath {
            return (isOnLeft, DescriptionOutlineNode(text: relativePath, isContainer: true))
        }

        return (isOnLeft, nil)
    }

    private func relative(path root: String, for path: String) -> String? {
        guard let range = path.range(of: root) else {
            return nil
        }
        // skip path separator
        let startIndex = path.index(after: range.upperBound)
        return String(path[startIndex ..< path.endIndex])
    }

    @objc
    func closeSheet(_: AnyObject) {
        sheetParent?.endSheet(self)
    }

    // MARK: - NSOulineView delegates messages

    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        let node = item as? DescriptionOutlineNode ?? compareItems

        guard let children = node?.children else {
            return 0
        }
        return children.count
    }

    func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let node = item as? DescriptionOutlineNode ?? compareItems

        guard let node else {
            return false
        }

        return node.isContainer
    }

    func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let node = item as? DescriptionOutlineNode ?? compareItems

        guard let children = node?.children else {
            fatalError("Children cannot be nil")
        }
        return children[index]
    }

    func outlineView(_: NSOutlineView, objectValueFor _: NSTableColumn?, byItem item: Any?) -> Any? {
        guard let item = item as? DescriptionOutlineNode else {
            return nil
        }

        return item.text
    }

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        outlineView.parent(forItem: item) == nil
    }
}
