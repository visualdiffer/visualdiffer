//
//  HistoryController.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/07/20.
//  Copyright (c) 2020 visualdiffer.com
//

import os.log

@MainActor protocol HistoryControllerDelegate: AnyObject {
    func history(controller: HistoryController, selectedEntities entities: [HistoryEntity])
    func history(controller: HistoryController, doubleClickedEntity entity: HistoryEntity?)

    func history(controller: HistoryController, droppedPaths paths: [URL]) -> Bool
}

@MainActor class HistoryController: NSObject, NSTableViewDelegate, NSTableViewDataSource, TableViewCommonDelegate {
    lazy var scrollView: NSScrollView = {
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

    var delegate: HistoryControllerDelegate?

    lazy var tableView: NSTableView = {
        let view = HistoryTableView(frame: .zero)

        view.dataSource = self
        view.delegate = self
        view.target = self
        view.doubleAction = #selector(handleDoubleClick)
        view.menu = contextMenu()

        return view
    }()

    private var results: NSFetchedResultsController<HistoryEntity>
    private lazy var resultsControllerDelegate = HistoryFetchedResultsControllerDelegate(tableView: tableView)

    override init() {
        results = NSFetchedResultsController(
            fetchRequest: HistoryEntity.requestUpdateTime(),
            managedObjectContext: HistorySessionManager.shared.historyMOC,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        super.init()

        setupResults()
    }

    func contextMenu() -> NSMenu {
        let menu = NSMenu(title: NSLocalizedString("Contextual Menu", comment: ""))
        menu.autoenablesItems = false

        menu.addItem(
            withTitle: NSLocalizedString("Remove", comment: ""),
            action: #selector(removeHistory),
            keyEquivalent: ""
        )
        .target = self
        menu.addItem(
            withTitle: NSLocalizedString("Select Invalid Paths", comment: ""),
            action: #selector(selectInvalidPaths),
            keyEquivalent: ""
        )
        .target = self

        return menu
    }

    @MainActor func setupResults() {
        results.delegate = resultsControllerDelegate
        try? results.performFetch()
        tableView.reloadData()
    }

    @objc @MainActor func handleDoubleClick(_: AnyObject) {
        let row = tableView.clickedRow

        // make sure double click was not in table header
        if row != -1,
           let delegate {
            delegate.history(controller: self, doubleClickedEntity: results.fetchedObjects?[row])
        }
    }

    // MARK: - NSTableView delegate and datasource methods

    func tableViewSelectionDidChange(_: Notification) {
        guard let delegate,
              let fetchedObjects = results.fetchedObjects else {
            return
        }
        var entities = [HistoryEntity]()

        for idx in tableView.selectedRowIndexes {
            entities.append(fetchedObjects[idx])
        }

        delegate.history(controller: self, selectedEntities: entities)
    }

    func numberOfRows(in _: NSTableView) -> Int {
        guard let fetchedObjects = results.fetchedObjects else {
            return 0
        }
        return fetchedObjects.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier,
              let entity = results.fetchedObjects?[row] else {
            return nil
        }
        let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? HistoryEntityTableCellView
            ?? HistoryEntityTableCellView(identifier: identifier)

        cell.pattern = resultsControllerDelegate.pattern
        cell.setupCell(entity: entity)

        return cell
    }

    func tableView(_: NSTableView, heightOfRow _: Int) -> CGFloat {
        80
    }

    // MARK: Drag&Drop

    func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow _: Int, proposedDropOperation _: NSTableView.DropOperation) -> NSDragOperation {
        var result: NSDragOperation = []

        tableView.setDropRow(-1, dropOperation: .on)
        let pasteboard = info.draggingPasteboard

        guard pasteboard.availableType(from: [NSPasteboard.PasteboardType.fileURL]) != nil,
              let arr = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return result
        }

        if arr.count < 2 {
            let isOk = FileManager.default.fileExists(atPath: arr[0].osPath, isDirectory: nil)
            if isOk {
                result = .copy
            }
        } else {
            if arr[0].matchesFileType(of: arr[1]) {
                result = .copy
            }
        }

        return result
    }

    func tableView(_: NSTableView, acceptDrop info: any NSDraggingInfo, row _: Int, dropOperation _: NSTableView.DropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard

        guard pasteboard.availableType(from: [NSPasteboard.PasteboardType.fileURL]) != nil,
              let arr = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              let delegate else {
            return false
        }

        return delegate.history(controller: self, droppedPaths: arr)
    }

    // To receive keydown declare the table class as TOPTableViewCommon inside the XIB definition
    func tableViewCommonKeyDown(_ tableView: NSTableView, event: NSEvent) -> Bool {
        if event.isDeleteShortcutKey(true) {
            removeEntity(indexes: tableView.selectedRowIndexes)
            return true
        }

        if let delegate,
           let entity = results.fetchedObjects?[tableView.selectedRow],
           let str = event.charactersIgnoringModifiers,
           !str.isEmpty,
           let key = str[str.startIndex].asciiValue {
            if key == NSCarriageReturnCharacter || key == NSEnterCharacter {
                delegate.history(controller: self, doubleClickedEntity: entity)
                return true
            }
        }
        return false
    }

    // MARK: - Private methods

    @MainActor private func removeEntity(indexes: IndexSet) {
        if indexes.isEmpty {
            return
        }
        guard let fetchedObjects = results.fetchedObjects else {
            return
        }
        for row in indexes.reversed() {
            HistorySessionManager.shared.historyMOC.delete(fetchedObjects[row])
        }
        do {
            try HistorySessionManager.shared.historyMOC.save()
        } catch {
            if let window = tableView.window {
                NSAlert(error: error).beginSheetModal(for: window)
            }
            Logger.ui.error("Unable to delete history, reason \(error)")
        }
    }

    @objc @MainActor func removeHistory(_: AnyObject) {
        removeEntity(indexes: tableView.selectedRowIndexes)
    }

    @objc @MainActor func selectInvalidPaths(_: AnyObject) {
        guard let fetchedObjects = results.fetchedObjects else {
            return
        }
        let fm = FileManager.default
        var indexSet = IndexSet()

        for (idx, entity) in fetchedObjects.enumerated() {
            if let entityLeftPath = entity.leftPath,
               let entityRightPath = entity.rightPath,
               !fm.fileExists(atPath: entityLeftPath) || !fm.fileExists(atPath: entityRightPath) {
                indexSet.insert(idx)
            }
        }

        tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        tableView.window?.makeFirstResponder(tableView)
    }

    @MainActor func filterFor(pattern: String?) {
        if let pattern, !pattern.isEmpty {
            resultsControllerDelegate.pattern = pattern
            results.fetchRequest.predicate = NSPredicate(format: "(leftPath contains[cd] %@) OR (rightPath contains[cd] %@)", pattern, pattern)
        } else {
            resultsControllerDelegate.pattern = nil
            results.fetchRequest.predicate = nil
        }

        do {
            try results.performFetch()
        } catch {
            Logger.ui.error("Unresolved error \(error)")
        }

        tableView.reloadData()
    }
}
