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

    func isRunning(_: FolderReader) -> Bool {
        guard let controller else {
            return false
        }

        return DispatchQueue.main.sync {
            controller.running
        }
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
            DispatchQueue.main.sync { controller.rootFoldersDidRead(folderReader: folderReader, foldersOnRoot: folderCount) }
        case let .willTraverse(item):
            DispatchQueue.main.async { controller.willTraverse(item) }
        case let .didTraverse(item):
            DispatchQueue.main.async { controller.didTraverse(folderReader: folderReader, item) }
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
