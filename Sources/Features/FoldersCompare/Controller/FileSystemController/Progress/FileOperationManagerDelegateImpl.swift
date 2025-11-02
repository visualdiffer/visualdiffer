//
//  FileOperationManagerDelegateImpl.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/03/16.
//  Copyright (c) 2016 visualdiffer.com
//

class FileOperationManagerDelegateImpl: FileOperationManagerDelegate {
    private(set) weak var progressIndicatorController: ProgressIndicatorController?

    init(progressIndicatorController: ProgressIndicatorController) {
        self.progressIndicatorController = progressIndicatorController
    }

    func waitPause(for _: FileOperationManager) {
        guard let pic = progressIndicatorController else {
            return
        }

        DispatchQueue.main.sync {
            pic.waitPause()
        }
    }

    func isRunning(_: FileOperationManager) -> Bool {
        guard let pic = progressIndicatorController else {
            return false
        }

        return DispatchQueue.main.sync {
            pic.isRunning()
        }
    }

    func fileManager(
        _: FileOperationManager,
        canReplaceFromPath fromPath: String,
        fromAttrs: [FileAttributeKey: Any]?,
        toPath: String,
        toAttrs: [FileAttributeKey: Any]?
    ) -> Bool {
        guard let pic = progressIndicatorController else {
            return false
        }

        let fromAttributes = fromAttrs?.toFileAttributes()
        let toAttributes = toAttrs?.toFileAttributes()

        return DispatchQueue.main.sync {
            pic.canReplace(
                fromPath: fromPath,
                fromAttrs: fromAttributes,
                toPath: toPath,
                toAttrs: toAttributes
            )
        }
    }

    func fileManager(_: FileOperationManager, initForItem item: CompareItem) {
        guard let pic = progressIndicatorController else {
            return
        }
        let path = item.path ?? ""

        DispatchQueue.main.async {
            pic.updateItem(path: path)
        }
    }

    func fileManager(_: FileOperationManager, updateForItem item: CompareItem) {
        guard let pic = progressIndicatorController else {
            return
        }

        let path = item.path ?? ""
        let isFile = item.isFile
        let fileSize = item.fileSize

        DispatchQueue.main.async {
            pic.updateItem(
                path: path,
                isFile: isFile,
                fileSize: fileSize
            )
        }
    }

    func fileManager(_: FileOperationManager, addError error: any Error, forItem item: CompareItem) {
        guard let pic = progressIndicatorController else {
            return
        }
        let path = item.path ?? ""

        DispatchQueue.main.async {
            pic.add(error: error as NSError, forPath: path)
        }
    }

    func fileManager(_: FileOperationManager, startBigFileOperationForItem item: CompareItem) {
        guard let pic = progressIndicatorController else {
            return
        }
        let fileSize = item.fileSize

        DispatchQueue.main.async {
            pic.prepare(with: fileSize)
        }
    }

    func isBigFileOperationCancelled(_: FileOperationManager) -> Bool {
        guard let pic = progressIndicatorController else {
            return false
        }

        return DispatchQueue.main.sync {
            pic.fileOpCancelled
        }
    }

    func isBigFileOperationCompleted(_: FileOperationManager) -> Bool {
        guard let pic = progressIndicatorController else {
            return false
        }

        return DispatchQueue.main.sync {
            pic.fileOpCompleted
        }
    }

    func fileManager(_: FileOperationManager, setCancelled cancelled: Bool) {
        guard let pic = progressIndicatorController else {
            return
        }

        DispatchQueue.main.async {
            pic.fileOpCancelled = cancelled
            // passing 0 to updateBytesCompleted ensures the UI is cleared
            pic.update(
                completedBytes: 0,
                totalBytes: 0,
                throughput: 0
            )
        }
    }

    func fileManager(_: FileOperationManager, setCompleted completed: Bool) {
        guard let pic = progressIndicatorController else {
            return
        }

        DispatchQueue.main.async {
            pic.fileOpCompleted = completed
            // passing 0 to updateBytesCompleted ensures the UI is cleared
            pic.update(
                completedBytes: 0,
                totalBytes: 0,
                throughput: 0
            )
        }
    }

    func fileManager(
        _: FileOperationManager,
        updateBytesCompleted bytesCompleted: Double,
        totalBytes: Double,
        throughput: Double
    ) {
        guard let pic = progressIndicatorController else {
            return
        }

        DispatchQueue.main.async {
            pic.update(
                completedBytes: Int64(bytesCompleted),
                totalBytes: Int64(totalBytes),
                throughput: Int64(throughput)
            )
        }
    }
}

extension ProgressIndicatorController {
    func canReplace(
        fromPath: String,
        fromAttrs: FileAttributes?,
        toPath: String,
        toAttrs: FileAttributes?
    ) -> Bool {
        canReplace(
            fromPath: fromPath,
            fromAttrs: fromAttrs?.toFileAttributeKeys(),
            toPath: toPath,
            toAttrs: toAttrs?.toFileAttributeKeys()
        )
    }
}
