//
//  FolderReaderDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/01/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

public enum FolderReaderStatus: Sendable {
    case will(startAt: Date)
    case did(endAt: Date, startedAt: Date)
    case rootFoldersDidRead(Int)
    case willTraverse(CompareItem)
    case didTraverse(CompareItem)
}

public protocol FolderReaderDelegate: AnyObject {
    func isRunning(_ folderReader: FolderReader) -> Bool

    func progress(_ folderReader: FolderReader, status: FolderReaderStatus)

    @discardableResult
    func folderReader(_ folderReader: FolderReader, handleError error: Error, forPath: URL) -> Bool
}
