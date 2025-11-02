//
//  UserDefinedRulesBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class UserDefinedRulesBox: PreferencesBox,
    @preconcurrency NSTableViewDataSource,
    NSTableViewDelegate,
    NSMenuItemValidation,
    TableViewCommonDelegate {
    enum Identifier {
        static let leftExpression = NSUserInterfaceItemIdentifier(rawValue: "leftExpression")
        static let rightExpression = NSUserInterfaceItemIdentifier(rawValue: "rightExpression")
    }

    private lazy var rulesTableView: NSTableView = {
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

        // Enable dragging on NSTableView
        view.registerForDraggedTypes([NSPasteboard.PasteboardType.alignRule])
        view.setDraggingSourceOperationMask(.every, forLocal: true)
        view.setDraggingSourceOperationMask(.every, forLocal: false)

        let columns = [
            (Identifier.leftExpression, NSLocalizedString("Left Regular Expression", comment: "")),
            (Identifier.rightExpression, NSLocalizedString("Right Pattern Expression", comment: "")),
        ]
        for (identifier, title) in columns {
            let column = NSTableColumn(identifier: identifier)
            column.title = title
            column.resizingMask = [.autoresizingMask, .userResizingMask]

            view.addTableColumn(column)
        }

        view.delegate = self
        view.dataSource = self

        view.target = self
        view.doubleAction = #selector(handleDoubleClick)

        return view
    }()

    private lazy var tableScrollView: NSScrollView = {
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

        view.documentView = rulesTableView

        return view
    }()

    private lazy var actionBarView: ActionBarView = {
        let view = ActionBarView(frame: .zero)

        view.firstButton.target = self
        view.firstButton.action = #selector(addAlignRule)

        view.secondButton.target = self
        view.secondButton.action = #selector(deleteAlignRules)
        // initially is disabled
        view.secondButton.isEnabled = false

        if let menu = view.popup.menu {
            menu.addItem(
                withTitle: NSLocalizedString("Edit Rule...", comment: ""),
                action: #selector(updateAlignRule),
                keyEquivalent: ""
            )
            .target = self
            let item = menu.addItem(
                withTitle: NSLocalizedString("Duplicate Rule...", comment: ""),
                action: #selector(duplicateAlignRule),
                keyEquivalent: "d"
            )
            item.target = self
            item.keyEquivalentModifierMask = .command
        }

        view.popup.target = self

        return view
    }()

    private lazy var label: NSTextField = {
        let view = NSTextField.labelWithTitle(
            NSLocalizedString("Drag items to change evaluation order (topmost first)", comment: "")
        )
        view.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)

        return view
    }()

    lazy var alignRuleWindow: AlignRuleWindow = .createSheet()

    var alignRules: [AlignRule] = []
    private var editedIndex = -1

    @objc override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        if let contentView {
            contentView.addSubview(tableScrollView)
            contentView.addSubview(actionBarView)
            contentView.addSubview(label)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            tableScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tableScrollView.bottomAnchor.constraint(equalTo: actionBarView.topAnchor),
            tableScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),

            actionBarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            actionBarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @objc func addAlignRule(_: AnyObject) {
        openAlignRuleWindow(
            AlignRule(regExp: AlignRegExp(), template: AlignTemplate()),
            index: -1,
            mode: .insert
        )
    }

    @objc func updateAlignRule(_: AnyObject) {
        if !alignRules.isEmpty {
            openAlignRuleWindow(
                alignRules[rulesTableView.selectedRow],
                index: rulesTableView.selectedRow,
                mode: .update
            )
        }
    }

    @objc func deleteAlignRules(_: AnyObject?) {
        for row in rulesTableView.selectedRowIndexes.reversed() {
            alignRules.remove(at: row)
        }
        delegate?.preferenceBox(self, setObject: alignRules, forKey: .virtualAlignRules)
        rulesTableView.reloadData()
    }

    @objc func duplicateAlignRule(_: AnyObject) {
        let row = rulesTableView.selectedRow

        if row != -1 {
            openAlignRuleWindow(
                alignRules[row],
                index: -1,
                mode: .insert
            )
        }
    }

    func moveRule(from rowIndexes: IndexSet, to row: Int) -> IndexSet {
        let movedIndexes = alignRules.move(from: rowIndexes as IndexSet, to: row)

        delegate?.preferenceBox(self, setObject: alignRules, forKey: .virtualAlignRules)

        return movedIndexes
    }

    private func openAlignRuleWindow(
        _ rule: AlignRule,
        index: Int,
        mode: AlignRuleWindow.Mode
    ) {
        guard let window else {
            return
        }
        editedIndex = index
        alignRuleWindow.alignRules = alignRules
        alignRuleWindow.beginSheet(
            window,
            alignRule: rule,
            mode: mode
        ) {
            self.alignRule($0)
        }
    }

    func alignRule(_ returnCode: NSApplication.ModalResponse) {
        if returnCode == .OK {
            if let editedRule = alignRuleWindow.editedRule {
                // on update alignRule is already inside array so it isn't necessary to add it
                if alignRuleWindow.mode == .insert {
                    alignRules.append(editedRule)
                } else {
                    alignRules[editedIndex] = editedRule
                }
                rulesTableView.reloadData()
                delegate?.preferenceBox(self, setObject: alignRules, forKey: .virtualAlignRules)
            }
        }
    }

    // MARK: - TableView data source methods

    func numberOfRows(in _: NSTableView) -> Int {
        alignRules.count
    }

    func tableView(_: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let identifier = tableColumn?.identifier {
            if identifier == Identifier.leftExpression {
                return alignRules[row].regExp.pattern
            }
            if identifier == Identifier.rightExpression {
                return alignRules[row].template.pattern
            }
        }
        return nil
    }

    func tableViewSelectionDidChange(_: Notification) {
        actionBarView.secondButton.isEnabled = rulesTableView.selectedRow != -1
    }

    func tableViewCommonKeyDown(_: NSTableView, event: NSEvent) -> Bool {
        if event.isDeleteShortcutKey(true) {
            if actionBarView.secondButton.isEnabled {
                deleteAlignRules(nil)
            }
            return true
        }
        return false
    }

    // MARK: Drag and Drop

    func tableView(_: NSTableView, validateDrop _: any NSDraggingInfo, proposedRow _: Int, proposedDropOperation _: NSTableView.DropOperation) -> NSDragOperation {
        .every
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation _: NSTableView.DropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard

        guard pasteboard.availableType(from: [.alignRule]) != nil else {
            return false
        }

        if let rowData = info.draggingPasteboard.data(forType: .alignRule),
           let rowIndexes = try? NSKeyedUnarchiver.unarchivedObject(
               ofClass: NSIndexSet.self,
               from: rowData
           ) {
            let movedIndexes = moveRule(from: rowIndexes as IndexSet, to: row)
            tableView.selectRowIndexes(movedIndexes, byExtendingSelection: false)
            tableView.reloadData()

            return true
        }

        return false
    }

    func tableView(_: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: rowIndexes,
            requiringSecureCoding: false
        ) else {
            return false
        }

        pboard.declareTypes([.alignRule], owner: self)
        pboard.setData(data, forType: .alignRule)
        return true
    }

    @objc func handleDoubleClick(_ sender: AnyObject) {
        if rulesTableView.clickedRow != -1 { // make sure double click was not in table header
            updateAlignRule(sender)
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        var enabled = true
        let action = menuItem.action

        if action == #selector(updateAlignRule) {
            enabled = rulesTableView.selectedRow != -1
        } else if action == #selector(duplicateAlignRule) {
            enabled = rulesTableView.selectedRow != -1
        }

        return enabled
    }

    override func reloadData() {
        alignRules = if let rules = delegate?.preferenceBox(self, objectForKey: .virtualAlignRules) as? [AlignRule] {
            rules
        } else {
            []
        }

        rulesTableView.reloadData()
    }
}

extension NSPasteboard.PasteboardType {
    static let alignRule = NSPasteboard.PasteboardType("AlignRulePboardType")
}
