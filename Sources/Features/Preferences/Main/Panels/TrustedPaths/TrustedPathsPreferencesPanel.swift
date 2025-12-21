//
//  TrustedPathsPreferencesPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/08/15.
//  Copyright (c) 2015 visualdiffer.com
//

class TrustedPathsPreferencesPanel: NSView, NSTableViewDataSource, NSTableViewDelegate,
    TableViewCommonDelegate, PreferencesPanelDataSource {
    private lazy var title: NSTextField = {
        let view = NSTextField(frame: .zero)

        view.stringValue = NSLocalizedString(
            "Access to paths without showing file selection dialog every time",
            comment: ""
        )
        view.font = NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
        view.isBordered = false
        view.isBezeled = false
        view.isEnabled = false
        view.isSelectable = false
        view.textColor = NSColor.controlTextColor
        view.backgroundColor = NSColor.controlColor
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var subTitle: NSTextField = {
        let view = NSTextField(frame: .zero)

        view.stringValue = NSLocalizedString("Click + or drag a folder onto the list", comment: "")
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        view.isBordered = false
        view.isBezeled = false
        view.isEnabled = false
        view.isSelectable = false
        view.textColor = NSColor.controlTextColor
        view.backgroundColor = NSColor.controlColor
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var pathTableScrollView: NSScrollView = {
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

        view.documentView = pathTableView

        return view
    }()

    private lazy var pathTableView: NSTableView = {
        let view = TableViewCommon(frame: .zero)

        view.allowsEmptySelection = true
        view.allowsColumnReordering = false
        view.allowsColumnResizing = true
        view.allowsMultipleSelection = true
        view.allowsColumnSelection = true
        view.allowsTypeSelect = true
        view.usesAlternatingRowBackgroundColors = true

        view.focusRingType = .none
        view.allowsExpansionToolTips = true
        view.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        view.autosaveTableColumns = false
        view.intercellSpacing = .zero
        view.headerView = nil

        // Enable dragging on NSTableView
        view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        view.setDraggingSourceOperationMask(.every, forLocal: true)
        view.setDraggingSourceOperationMask(.every, forLocal: false)

        // the column is full width and it resizes properly when the table changes dimensions
        // see https://stackoverflow.com/a/15390614/195893
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Paths"))
        column.resizingMask = .autoresizingMask
        view.addTableColumn(column)
        view.sizeLastColumnToFit()

        view.delegate = self
        view.dataSource = self

        return view
    }()

    private lazy var actionBar: ActionBarView = {
        let view = ActionBarView(frame: .zero)

        view.firstButton.toolTip = NSLocalizedString("Add a folder to trusted paths", comment: "")

        view.secondButton.toolTip = NSLocalizedString(
            "Remove selected items from the list",
            comment: ""
        )

        view.firstButton.target = self
        view.firstButton.action = #selector(choosePaths)

        view.secondButton.target = self
        view.secondButton.action = #selector(removePaths)

        if let menu = view.popup.menu {
            menu.addItem(
                withTitle: NSLocalizedString("Select invalid paths", comment: ""),
                action: #selector(selectInvalidPaths),
                keyEquivalent: ""
            ).target = self
        }
        view.popup.target = self

        return view
    }()

    var trustedPaths = [String]()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        addSubview(title)
        addSubview(subTitle)
        addSubview(pathTableScrollView)
        addSubview(actionBar)

        setupConstraints()
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            title.topAnchor.constraint(equalTo: topAnchor, constant: 5),

            subTitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            subTitle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            subTitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),

            pathTableScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            pathTableScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            pathTableScrollView.topAnchor.constraint(equalTo: subTitle.bottomAnchor, constant: 2),
            pathTableScrollView.heightAnchor.constraint(equalToConstant: 200),
            pathTableScrollView.bottomAnchor.constraint(equalTo: actionBar.topAnchor, constant: -2),

            actionBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            actionBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])
    }

    /**
     * If the array doesn't contain @path, adds it at index position or at the end
     * Return true if the passed array contains the path, false otherwise
     */
    private func insert(path: URL, destArray arr: inout [String]) -> (Bool, Int) {
        var found = false
        let index = arr.firstIndex {
            let result = $0.caseInsensitiveCompare(path.path)
            if result == .orderedDescending {
                return true
            } else if result == .orderedSame {
                found = true
                return true
            }
            return false
        }

        var insertIndex = 0
        if !found {
            if let index {
                arr.insert(path.path, at: index)
                insertIndex = index
            } else {
                arr.append(path.path)
                insertIndex = arr.count - 1
            }
        }
        return (found, insertIndex)
    }

    private func insert(paths: [URL]) {
        var indexSet = IndexSet()

        for path in paths {
            let (containsItem, index) = insert(path: path, destArray: &trustedPaths)
            indexSet.insert(index)
            if !containsItem {
                SecureBookmark.shared.add(path, searchClosestPath: false)
            }
        }
        if let index = indexSet.first {
            pathTableView.reloadData()
            pathTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
            pathTableView.scrollRowToVisible(index)
        }
    }

    @objc func choosePaths(_: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.title = NSLocalizedString("Select Trusted Paths", comment: "")
        // since 10.11 the title is no longer shown so we use the message property
        openPanel.message = NSLocalizedString("Select Trusted Paths", comment: "")
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = true

        if openPanel.runModal() == .OK {
            insert(paths: openPanel.urls)
        }

        // if modal returns NSModalResponseCancel the window is no longer if front
        pathTableView.window?.makeKeyAndOrderFront(nil)
        pathTableView.window?.makeFirstResponder(pathTableView)
    }

    @objc func removePaths(_: AnyObject) {
        let selectedRows = pathTableView.selectedRowIndexes
        var paths = [String]()

        for row in selectedRows.reversed() {
            paths.append(trustedPaths[row])
            trustedPaths.remove(at: row)
        }
        SecureBookmark.shared.removePaths(paths)

        pathTableView.reloadData()
        pathTableView.deselectAll(nil)
        pathTableView.window?.makeFirstResponder(pathTableView)
    }

    @objc func selectInvalidPaths(_: AnyObject) {
        let fm = FileManager.default
        var indexSet = IndexSet()

        for (idx, path) in trustedPaths.enumerated() where !fm.fileExists(atPath: path) {
            indexSet.insert(idx)
        }
        pathTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
    }

    func reloadData() {
        guard let arr = SecureBookmark.shared.securedPaths?.keys else {
            return
        }
        trustedPaths = arr.map(\.self)
        trustedPaths.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        pathTableView.reloadData()
    }

    // MARK: - NSTableView data source messages

    func numberOfRows(in _: NSTableView) -> Int {
        trustedPaths.count
    }

    func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        guard let identifier = tableColumn?.identifier else {
            return nil
        }
        let cell = tableView.makeView(
            withIdentifier: identifier,
            owner: self
        ) as? FilePathTableCellView ??
            FilePathTableCellView(identifier: identifier)

        cell.update(path: trustedPaths[row])

        return cell
    }

    func tableView(
        _ tableView: NSTableView,
        validateDrop _: any NSDraggingInfo,
        proposedRow _: Int,
        proposedDropOperation _: NSTableView.DropOperation
    ) -> NSDragOperation {
        tableView.setDropRow(-1, dropOperation: .on)
        return .copy
    }

    func tableView(
        _: NSTableView,
        acceptDrop info: any NSDraggingInfo,
        row _: Int,
        dropOperation _: NSTableView.DropOperation
    ) -> Bool {
        let pasteboard = info.draggingPasteboard

        guard pasteboard.availableType(from: [NSPasteboard.PasteboardType.fileURL]) != nil,
              let arr = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]
        else {
            return false
        }

        insert(paths: arr)
        return true
    }

    // To receive keydown declare the table class as TOPTableViewCommon inside the XIB definition
    func tableViewCommonKeyDown(_ tableView: NSTableView, event: NSEvent) -> Bool {
        if event.isDeleteShortcutKey(true) {
            let rowIndexes = tableView.selectedRowIndexes
            if let index = rowIndexes.first {
                removePaths(tableView)
                tableView.selectRow(
                    closestTo: index,
                    byExtendingSelection: false,
                    ensureVisible: true
                )
            }
            return true
        }
        return false
    }
}
