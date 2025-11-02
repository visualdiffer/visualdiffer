//
//  MockFileOperationManagerDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

@testable import VisualDiffer

class MockFileOperationManagerDelegate: FileOperationManagerDelegate {
    let confirmReplace: ConfirmReplace
    var isRunning: Bool
    var errors = [any Error]()

    init(
        replaceAll: Bool = true,
        isRunning: Bool = true
    ) {
        confirmReplace = ConfirmReplace(
            yesToAll: replaceAll,
            noToAll: false
        ) { _, _ in false }
        self.isRunning = isRunning
    }

    func waitPause(for _: FileOperationManager) {}

    func isRunning(_: FileOperationManager) -> Bool {
        isRunning
    }

    func fileManager(
        _: FileOperationManager,
        canReplaceFromPath fromPath: String,
        fromAttrs: [FileAttributeKey: Any]?,
        toPath: String,
        toAttrs: [FileAttributeKey: Any]?
    ) -> Bool {
        confirmReplace.canReplace(
            fromPath: fromPath,
            fromAttrs: fromAttrs,
            toPath: toPath,
            toAttrs: toAttrs
        )
    }

    func fileManager(_: FileOperationManager, initForItem _: CompareItem) {}

    func fileManager(_: FileOperationManager, updateForItem _: CompareItem) {}

    func fileManager(_: FileOperationManager, addError error: any Error, forItem _: CompareItem) {
        errors.append(error)
    }

    func fileManager(_: FileOperationManager, startBigFileOperationForItem _: CompareItem) {}

    func isBigFileOperationCancelled(_: FileOperationManager) -> Bool {
        false
    }

    func isBigFileOperationCompleted(_: FileOperationManager) -> Bool {
        false
    }

    func fileManager(_: FileOperationManager, setCancelled _: Bool) {}

    func fileManager(_: FileOperationManager, setCompleted _: Bool) {}

    func fileManager(_: FileOperationManager, updateBytesCompleted _: Double, totalBytes _: Double, throughput _: Double) {}
}
