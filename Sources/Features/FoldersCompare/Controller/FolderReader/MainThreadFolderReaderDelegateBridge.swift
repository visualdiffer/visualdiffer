//
//  MainThreadFolderReaderDelegateBridge.swift
//  VisualDiffer
//
//  Created by davide ficano on 22/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

/**
 * This bridge is used to call on main thread all FolderReaderDelegate methods
 */
class MainThreadFolderReaderDelegateBridge: FolderReaderDelegate {
    private weak var controller: FoldersWindowController?

    init(_ controller: FoldersWindowController) {
        self.controller = controller
    }

    // the flag is lock-based so the poll no longer hops to the main thread
    func isRunning(_: FolderReader) -> Bool {
        controller?.running ?? false
    }

    func progress(_ folderReader: FolderReader, status: FolderReaderStatus) {
        guard let controller else {
            return
        }

        switch status {
        case let .will(startAt):
            DispatchQueue.main.sync { controller.will(startAt: startAt) }
        case let .did(endAt, startedAt):
            DispatchQueue.main.sync { controller.did(endAt: endAt, startedAt: startedAt) }
        case let .rootFoldersDidRead(folderCount):
            DispatchQueue.main.sync {
                controller.rootFoldersDidRead(folderReader: folderReader, foldersOnRoot: folderCount)
            }
        // the item callbacks are the barrier that keeps the
        // reader from mutating the item while the main thread reads it
        case let .willTraverse(item):
            DispatchQueue.main.sync { controller.willTraverse(item) }
        case let .didTraverse(item):
            DispatchQueue.main.sync { controller.didTraverse(folderReader: folderReader, item) }
        }
    }

    func folderReader(_: FolderReader, handleError error: any Error, forPath path: URL) -> Bool {
        guard let controller else {
            return false
        }

        DispatchQueue.main.async {
            _ = controller.handleError(error: error, forPath: path)
        }

        return true
    }
}
