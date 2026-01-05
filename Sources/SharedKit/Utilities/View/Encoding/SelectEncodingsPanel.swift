//
//  SelectEncodingsPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

class SelectEncodingsPanel: NSWindow, NSTableViewDataSource, NSTableViewDelegate {
    private lazy var titleText: NSTextField = {
        let view = NSTextField(frame: .zero)

        view.isEditable = false
        view.isBordered = false
        view.drawsBackground = false
        view.translatesAutoresizingMaskIntoConstraints = false

        let cell = TextFieldVerticalCentered()
        cell.lineBreakMode = .byClipping
        cell.title = NSLocalizedString("Select encodings to show on the main list", comment: "")

        view.cell = cell

        // set the font after the cell otherwise it is lost
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

        return view
    }()

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

        view.documentView = tableView

        return view
    }()

    private lazy var tableView: NSTableView = {
        let view = TableViewCommon(frame: .zero)

        view.allowsEmptySelection = true
        view.allowsColumnReordering = false
        view.allowsColumnResizing = true
        view.allowsMultipleSelection = true
        view.allowsColumnSelection = true
        view.allowsTypeSelect = true

        view.allowsExpansionToolTips = true
        view.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        view.autosaveTableColumns = false
        view.intercellSpacing = .zero
        view.headerView = nil

        // the column is full width and it resizes properly when the table changes dimensions
        // see https://stackoverflow.com/a/15390614/195893
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Encodings"))
        column.resizingMask = .autoresizingMask
        view.addTableColumn(column)
        view.sizeLastColumnToFit()

        view.delegate = self
        view.dataSource = self

        return view
    }()

    private lazy var standardButtons: StandardButtons = {
        let view = StandardButtons(
            primaryTitle: NSLocalizedString("OK", comment: ""),
            secondaryTitle: NSLocalizedString("Cancel", comment: ""),
            target: self,
            action: #selector(closeSheet)
        )

        view.primaryButton.tag = NSApplication.ModalResponse.OK.rawValue
        view.secondaryButton.tag = NSApplication.ModalResponse.cancel.rawValue

        return view
    }()

    var encodingsList = [String.Encoding]() {
        didSet {
            tableView.reloadData()
        }
    }

    var onClose: (@MainActor (NSApplication.ModalResponse, [String.Encoding]) -> Void)?

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )

        minSize = NSSize(width: 400, height: 200)

        setupViews()
    }

    private func setupViews() {
        if let contentView {
            contentView.addSubview(titleText)
            contentView.addSubview(scrollView)
            contentView.addSubview(standardButtons)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }
        let heightConstraint = scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        heightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            titleText.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleText.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleText.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: titleText.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            heightConstraint,
            scrollView.bottomAnchor.constraint(equalTo: standardButtons.topAnchor, constant: -20),

            standardButtons.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            standardButtons.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    static func createSheet() -> SelectEncodingsPanel {
        let styleMask: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
        ]

        return SelectEncodingsPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
    }

    @objc func closeSheet(_ sender: AnyObject) {
        let response = NSApplication.ModalResponse(sender.tag)
        var selectedEncodings = [String.Encoding]()
        if response == .OK {
            selectedEncodings = tableView.selectedRowIndexes.map { encodingsList[$0] }
        }

        onClose?(response, selectedEncodings)
        sheetParent?.endSheet(self)
    }

    func select(encodings selected: IndexSet) {
        tableView.selectRowIndexes(selected, byExtendingSelection: false)
    }

    func numberOfRows(in _: NSTableView) -> Int {
        encodingsList.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else {
            return nil
        }
        let cell = tableView.makeView(
            withIdentifier: identifier,
            owner: self
        ) as? NSTableCellView ?? createCell(identifier)

        cell.textField?.stringValue = String.localizedName(of: encodingsList[row])

        return cell
    }

    private func createCell(_ identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = identifier

        let textField = NSTextField(frame: cell.bounds)
        textField.autoresizingMask = [.width, .height]

        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

        cell.addSubview(textField)
        cell.textField = textField

        return cell
    }
}
