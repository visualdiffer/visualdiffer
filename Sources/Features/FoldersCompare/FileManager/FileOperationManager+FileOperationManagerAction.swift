//
//  FileOperationManager+FileOperationManagerAction.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

import os.log

extension FileOperationManager: FileOperationManagerAction {
    func copy(_ srcRoot: CompareItem, srcBaseDir: String, destBaseDir: String) {
        let copyItem = CopyCompareItem(
            operationManager: self,
            bigFileSizeThreshold: defaultBigFileSizeThreshold
        )

        copyItem.copy(
            srcRoot: srcRoot,
            srcBaseDir: URL(filePath: srcBaseDir, directoryHint: .isDirectory),
            destBaseDir: URL(filePath: destBaseDir, directoryHint: .isDirectory)
        )
    }

    func move(
        _ srcRoot: CompareItem,
        srcBaseDir: String,
        destBaseDir: String
    ) {
        let moveItem = MoveCompareItem(
            operationManager: self,
            bigFileSizeThreshold: defaultBigFileSizeThreshold
        )

        moveItem.move(
            srcRoot: srcRoot,
            srcBaseDir: URL(filePath: srcBaseDir, directoryHint: .isDirectory),
            destBaseDir: URL(filePath: destBaseDir, directoryHint: .isDirectory)
        )
    }

    func delete(_ srcRoot: CompareItem, srcBaseDir: String) {
        let deleteItem = DeleteCompareItem(operationManager: self)

        deleteItem.delete(srcRoot, baseDir: URL(filePath: srcBaseDir, directoryHint: .isDirectory))
    }

    func touch(_ srcRoot: CompareItem, includeSubfolders: Bool, touch touchDate: Date?) {
        let touchItem = TouchCompareItem(operationManager: self)

        touchItem.touch(
            srcRoot: srcRoot,
            includeSubfolders: includeSubfolders,
            touchDate: touchDate
        )
    }

    func rename(_ srcRoot: CompareItem, toName: String) {
        let renameItem = RenameCompareItem(operationManager: self)

        renameItem.rename(
            srcRoot: srcRoot,
            toName: toName
        )
    }
}

#if DEBUG && __VD_SLOW_OP__
    func simulateSlowOperation(_ message: String, delay: TimeInterval = 2) {
        Logger.debug.info("Simulating slow operation \(message)")
        Thread.sleep(forTimeInterval: delay)
    }
#endif
