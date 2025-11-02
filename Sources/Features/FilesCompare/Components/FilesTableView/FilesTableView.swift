//
//  FilesTableView.swift
//  VisualDiffer
//
//  Created by davide ficano on 20/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

@MainActor protocol FilesTableViewDelegate: NSTableViewDelegate {
    func setLastUsedViewResponder(_ view: FilesTableView)
    func filesTableView(_ view: FilesTableView, scrollHorizontally leftScroll: Bool)
    func filesTableView(_ view: FilesTableView, doubleClick lickedRow: Int)
    func deleteKeyPressed(_ view: FilesTableView)
}

class FilesTableView: NSTableView, @preconcurrency DisplayPositionable, ViewLinkable {
    var linkedView: FilesTableView?
    var side: DisplaySide = .left
    var diffSide: DiffSide?
    var isEditAllowed = false
    @objc dynamic var isDirty = false {
        didSet {
            guard isDirty != oldValue,
                  let document = window?.windowController?.document else {
                return
            }

            // don't use NSDocumentController.currentDocument() because can be nil
            // when application is not active (eg when reloading file outside application)
            if isDirty {
                document.updateChangeCount(.changeDone)
            } else {
                document.updateChangeCount(.changeUndone)
            }
        }
    }

    var filesTableDelegate: FilesTableViewDelegate? {
        delegate as? FilesTableViewDelegate
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        allowsEmptySelection = true
        allowsColumnReordering = false
        allowsColumnResizing = true
        allowsMultipleSelection = true
        allowsColumnSelection = true
        allowsTypeSelect = true

        focusRingType = .none
        allowsExpansionToolTips = true
        columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        autosaveTableColumns = false
        intercellSpacing = .zero

        // Needed by drop
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        setDraggingSourceOperationMask(.every, forLocal: true)
        setDraggingSourceOperationMask(.every, forLocal: false)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("cellLineText"))

        addTableColumn(column)
        headerView = nil

        doubleAction = #selector(handleDoubleClick)
    }

    override func becomeFirstResponder() -> Bool {
        filesTableDelegate?.setLastUsedViewResponder(self)
        return super.becomeFirstResponder()
    }

    // MARK: Keys and mouse handlers

    @objc func handleDoubleClick(_: AnyObject) {
        if clickedRow != -1 { // make sure double click was not in table header
            filesTableDelegate?.filesTableView(self, doubleClick: clickedRow)
        }
    }

    override func keyDown(with event: NSEvent) {
        let keyCode = KeyCode(rawValue: event.keyCode)

        // When an arrow key is pressed the NSNumericPadKeyMask and NSFunctionKeyMask
        // are always set so we don't check them
        let isArrowKeyDownWithModifiers = event.modifierFlags.contains([.shift, .control, .option, .command])

        if event.isDeleteShortcutKey(true) {
            filesTableDelegate?.deleteKeyPressed(self)
        } else if keyCode == .leftArrow, !isArrowKeyDownWithModifiers {
            filesTableDelegate?.filesTableView(self, scrollHorizontally: true)
        } else if keyCode == .rightArrow, !isArrowKeyDownWithModifiers {
            filesTableDelegate?.filesTableView(self, scrollHorizontally: false)
        } else {
            super.keyDown(with: event)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)

        if event.deltaX != 0 {
            filesTableDelegate?.filesTableView(self, scrollHorizontally: event.deltaX > 0)
        }
    }

    func reloadData(restoreSelection: Bool) {
        if restoreSelection {
            let currentSelection = selectedRowIndexes
            reloadData()
            selectRowIndexes(currentSelection, byExtendingSelection: false)
        } else {
            reloadData()
        }
    }
}
