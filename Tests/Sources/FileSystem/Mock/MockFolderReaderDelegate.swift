//
//  MockFolderReaderDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

@testable import VisualDiffer

class MockFolderReaderDelegate: FolderReaderDelegate {
    var isRunning = false
    var errors = [Error]()

    init(isRunning: Bool) {
        self.isRunning = isRunning
    }

    func isRunning(_: VisualDiffer.FolderReader) -> Bool {
        isRunning
    }

    func progress(_: VisualDiffer.FolderReader, status _: VisualDiffer.FolderReaderStatus) {}

    func folderReader(_: VisualDiffer.FolderReader, handleError error: any Error, forPath _: URL) -> Bool {
        errors.append(error)
        return true
    }
}
