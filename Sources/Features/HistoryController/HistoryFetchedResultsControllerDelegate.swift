//
//  HistoryFetchedResultsControllerDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/07/20.
//  Copyright (c) 2020 visualdiffer.com
//

import os.log

typealias IndexPathPair = (IndexPath, IndexPath?)

@objc class HistoryFetchedResultsControllerDelegate: NSObject, @preconcurrency NSFetchedResultsControllerDelegate {
    private(set) var tableView: NSTableView
    @objc var pattern: String?

    private var objectChanges = [NSFetchedResultsChangeType: [IndexPathPair]]()

    @objc init(tableView: NSTableView) {
        self.tableView = tableView

        super.init()
    }

    func controllerWillChangeContent(_: NSFetchedResultsController<any NSFetchRequestResult>) {
        objectChanges.removeAll()
    }

    @MainActor func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        tableView.beginUpdates()

        onContentInserted(controller, array: objectChanges[.insert])
        onContentUpdated(controller, array: objectChanges[.update])
        onContentDeleted(controller, array: objectChanges[.delete])
        onContentMoved(controller, array: objectChanges[.move])

        tableView.endUpdates()

        let indexes = IndexSet(integer: 0)
        tableView.selectRowIndexes(indexes, byExtendingSelection: false)
        tableView.scrollRowToVisible(0)
    }

    func controller(
        _: NSFetchedResultsController<any NSFetchRequestResult>,
        didChange _: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        // The indexPath order is not guaranteed to be sequential (1, 2, 3) so removing items from table
        // the application could crash, to avoid this we collect all change types here
        // and then update the tableView inside the controllerDidChangeContent method
        // The idea comes from: https://github.com/visualdiffer/gityhub/blob/master/gityhub/gityhub/Controllers/CollectionViewDataFetcher.m#L116
        // To reproduce the crash try to delete last 3 rows from table
        // The error is: Serious application error.  Exception was caught during Core Data change processing.  This is usually a bug within an observer of NSManagedObjectContextObjectsDidChangeNotification.  NSTableView error inserting/removing/moving row X (numberOfRows: X). with userInfo (null)
        var changeSet = objectChanges[type] ?? []

        switch type {
        case .insert:
            if let newIndexPath {
                let item: IndexPathPair = (newIndexPath, nil)
                changeSet.append(item)
            }
        case .delete:
            if let indexPath {
                let item: IndexPathPair = (indexPath, nil)
                changeSet.append(item)
            }
        case .update:
            if let indexPath {
                let item: IndexPathPair = (indexPath, nil)
                changeSet.append(item)
            }
        case .move:
            if let indexPath,
               let newIndexPath {
                let item: IndexPathPair = (indexPath, newIndexPath)
                changeSet.append(item)
            }
        default:
            Logger.general.error("Found invalid type: \(type.rawValue)")
        }
        objectChanges[type] = changeSet
    }

    @MainActor func onContentInserted(
        _: NSFetchedResultsController<any NSFetchRequestResult>,
        array: [IndexPathPair]?
    ) {
        guard let array,
              !array.isEmpty else {
            return
        }
        var indexes = IndexSet()
        for (from, _) in array {
            indexes.insert(from.item)
        }
        tableView.insertRows(
            at: indexes,
            withAnimation: .effectFade
        )
    }

    @MainActor func onContentUpdated(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        array: [IndexPathPair]?
    ) {
        guard let array,
              !array.isEmpty else {
            return
        }
        for (from, _) in array {
            let row = from.item
            let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: true)
            if let cell = cell as? HistoryEntityTableCellView {
                cell.pattern = pattern
                if let entity = controller.fetchedObjects?[row] as? HistoryEntity {
                    cell.setupCell(entity: entity)
                }
            }
        }
    }

    @MainActor func onContentDeleted(
        _: NSFetchedResultsController<any NSFetchRequestResult>,
        array: [IndexPathPair]?
    ) {
        guard let array,
              !array.isEmpty else {
            return
        }
        var indexes = IndexSet()
        for (from, _) in array {
            indexes.insert(from.item)
        }
        tableView.removeRows(
            at: indexes,
            withAnimation: .effectFade
        )
    }

    @MainActor func onContentMoved(
        _: NSFetchedResultsController<any NSFetchRequestResult>,
        array: [IndexPathPair]?
    ) {
        guard let array,
              !array.isEmpty else {
            return
        }
        for (fromIndex, toIndex) in array {
            if let toIndex {
                tableView.removeRows(
                    at: IndexSet(integer: fromIndex.item),
                    withAnimation: .effectFade
                )
                tableView.insertRows(
                    at: IndexSet(integer: toIndex.item),
                    withAnimation: .effectFade
                )
            }
        }
    }
}
