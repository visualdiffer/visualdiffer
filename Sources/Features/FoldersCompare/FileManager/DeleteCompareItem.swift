//
//  DeleteCompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

import os.log

class DeleteCompareItem {
    struct DeleteResult {
        var srcRoot: CompareItem?
        var destRoot: CompareItem?
    }

    let operationManager: FileOperationManager
    private let fm = FileManager.default
    private let delegate: FileOperationManagerDelegate

    init(operationManager: FileOperationManager) {
        self.operationManager = operationManager
        delegate = operationManager.delegate
    }

    func delete(
        _ srcRoot: CompareItem,
        baseDir: URL
    ) {
        if !srcRoot.isValidFile {
            return
        }

        var srcCount = CompareSummary()
        var destCount = CompareSummary()

        doDelete(
            srcRoot,
            baseDir: baseDir,
            parentSrcCount: &srcCount,
            parentDestCount: &destCount,
            informDelegate: true
        )

        var parent = srcRoot.parent

        while let item = parent {
            item.addOlderFiles(-srcCount.olderFiles)
            item.addChangedFiles(-srcCount.changedFiles)
            item.addOrphanFiles(-srcCount.orphanFiles)
            item.addMatchedFiles(-srcCount.matchedFiles)
            item.addSubfoldersSize(-srcCount.subfoldersSize)
            item.addMismatchingTags(-srcCount.mismatchingTags)
            item.addMismatchingLabels(-srcCount.mismatchingLabels)

            if let destItem = item.linkedItem {
                destItem.addOlderFiles(destCount.olderFiles)
                destItem.addChangedFiles(destCount.changedFiles)
                destItem.addOrphanFiles(destCount.orphanFiles)
                destItem.addMatchedFiles(destCount.matchedFiles)
                destItem.addSubfoldersSize(destCount.subfoldersSize)
                destItem.addMismatchingTags(destCount.mismatchingTags)
                destItem.addMismatchingLabels(destCount.mismatchingLabels)
            }

            item.removeVisibleItems(filterConfig: operationManager.filterConfig)

            parent = item.parent
        }
    }

    @discardableResult
    func doDelete(
        _ srcRoot: CompareItem,
        baseDir: URL,
        informDelegate: Bool
    ) -> Bool {
        var parentSrcCount = CompareSummary()
        var parentDestCount = CompareSummary()

        return doDelete(
            srcRoot,
            baseDir: baseDir,
            parentSrcCount: &parentSrcCount,
            parentDestCount: &parentDestCount,
            informDelegate: informDelegate
        )
    }

    @discardableResult
    func doDelete(
        _ srcRoot: CompareItem,
        baseDir: URL,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        informDelegate: Bool
    ) -> Bool {
        if informDelegate {
            delegate.waitPause(for: operationManager)

            if !delegate.isRunning(operationManager) {
                return false
            }
        }
        if !srcRoot.isValidFile {
            return true
        }
        let isFiltered = srcRoot.isFiltered || !srcRoot.isDisplayed
        if !operationManager.includesFiltered, isFiltered {
            return true
        }

        let result = if srcRoot.isFile {
            deleteFile(
                srcRoot,
                parentSrcCount: &parentSrcCount,
                parentDestCount: &parentDestCount,
                informDelegate: informDelegate
            )
        } else {
            deleteFolder(
                srcRoot,
                baseDir: baseDir,
                parentSrcCount: &parentSrcCount,
                parentDestCount: &parentDestCount,
                informDelegate: informDelegate
            )
        }
        if let result {
            updateParentTimeStamp(result)
            updateFilteredStatus(result)
        }

        return true
    }

    private func updateParentTimeStamp(_ result: DeleteResult) {
        // The parent's modification time changes after a delete so refresh attributes
        if let parent = result.srcRoot?.parent,
           let path = parent.path,
           let attrs = try? fm.attributesOfItem(atPath: path) {
            parent.setAttributes(attrs, fileExtraOptions: operationManager.filterConfig.fileExtraOptions)
        }
    }

    private func updateFilteredStatus(_ result: DeleteResult) {
        if let srcRoot = result.srcRoot,
           let destRoot = result.destRoot,
           destRoot.isFiltered {
            // check if file is yet filtered after deleting
            let isFiltered = if let predicate = operationManager.filterConfig.predicate {
                destRoot.evaluate(filter: predicate)
            } else {
                false
            }
            srcRoot.isFiltered = isFiltered
            destRoot.isFiltered = isFiltered
        }
    }

    private func deleteFolder(
        _ srcRoot: CompareItem,
        baseDir: URL,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        informDelegate: Bool
    ) -> DeleteResult? {
        var srcCount = CompareSummary()
        var destCount = CompareSummary()

        // interate in reverse order because the collection changes while running
        for item in srcRoot.children.reversed() {
            // swiftlint:disable:next for_where
            if !doDelete(
                item,
                baseDir: baseDir,
                parentSrcCount: &srcCount,
                parentDestCount: &destCount,
                informDelegate: informDelegate
            ) {
                Logger.fs.warning("Stopped at folder process")
                break
            }
        }

        var result: DeleteResult?

        if operationManager.canRemoveDirectory(srcRoot) {
            if let path = srcRoot.path {
                do {
                    try fm.removeItem(atPath: path)
                } catch {
                    if informDelegate {
                        delegate.fileManager(operationManager, addError: error, forItem: srcRoot)
                    }
                }
                makeFolderInvalid(
                    srcRoot,
                    parentCount: &parentSrcCount,
                    itemCount: &srcCount
                )
                if let destRoot = srcRoot.linkedItem {
                    makeFolderOrphan(
                        destRoot,
                        parentCount: &parentDestCount,
                        itemCount: &destCount
                    )
                    if destRoot.isValidFile {
                        result = DeleteResult(srcRoot: srcRoot, destRoot: destRoot)
                    } else {
                        makeLinkedFilesInvalid(srcRoot, destRoot: destRoot)
                        result = DeleteResult()
                    }
                }
            }
        } else {
            updateFolderCounters(
                srcRoot,
                parentSrcCount: &parentSrcCount,
                parentDestCount: &parentDestCount,
                srcCount: &srcCount,
                destCount: &destCount
            )
        }
        return result
    }

    private func makeFolderInvalid(
        _ srcRoot: CompareItem,
        parentCount: inout CompareSummary,
        itemCount: inout CompareSummary
    ) {
        parentCount += itemCount
        if srcRoot.summary.hasMetadataTags {
            parentCount.mismatchingTags += 1
        }
        if srcRoot.summary.hasMetadataLabels {
            parentCount.mismatchingLabels += 1
        }
        if srcRoot.isOrphanFolder {
            srcRoot.addOrphanFolders(-1)
        } else {
            srcRoot.linkedItem?.addOrphanFolders(1)
        }
        srcRoot.path = nil
        srcRoot.setAttributes(nil, fileExtraOptions: [])

        // refresh isFolder
        srcRoot.linkedItemIsFolder(true)
    }

    private func makeFolderOrphan(
        _ destRoot: CompareItem,
        parentCount: inout CompareSummary,
        itemCount: inout CompareSummary
    ) {
        destRoot.addOlderFiles(itemCount.olderFiles)
        destRoot.addChangedFiles(itemCount.changedFiles)
        destRoot.addOrphanFiles(itemCount.orphanFiles)
        destRoot.addMatchedFiles(itemCount.matchedFiles)

        parentCount += itemCount
        destRoot.setMismatchingFolderMetadataTags(false)
        destRoot.setMismatchingFolderMetadataLabels(false)
    }

    private func updateFolderCounters(
        _ srcRoot: CompareItem,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        srcCount: inout CompareSummary,
        destCount: inout CompareSummary
    ) {
        srcRoot.addOlderFiles(-srcCount.olderFiles)
        srcRoot.addChangedFiles(-srcCount.changedFiles)
        srcRoot.addOrphanFiles(-srcCount.orphanFiles)
        srcRoot.addMatchedFiles(-srcCount.matchedFiles)
        srcRoot.addSubfoldersSize(-srcCount.subfoldersSize)
        parentSrcCount += srcCount

        if let destRoot = srcRoot.linkedItem {
            destRoot.addOlderFiles(destCount.olderFiles)
            destRoot.addChangedFiles(destCount.changedFiles)
            destRoot.addOrphanFiles(destCount.orphanFiles)
            destRoot.addMatchedFiles(destCount.matchedFiles)
            parentDestCount += destCount
        }
    }

    private func deleteFile(
        _ srcRoot: CompareItem,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        informDelegate: Bool
    ) -> DeleteResult? {
        guard let destRoot = srcRoot.linkedItem else {
            return nil
        }
        if informDelegate {
            delegate.fileManager(operationManager, initForItem: srcRoot)
        }

        var result: DeleteResult?

        do {
            try remove(item: srcRoot)

            parentSrcCount += srcRoot.summary
            parentSrcCount.subfoldersSize += srcRoot.fileSize

            if destRoot.isValidFile {
                makeFileOrphan(srcRoot, destRoot: destRoot, parentDestCount: &parentDestCount)
                result = DeleteResult(srcRoot: srcRoot, destRoot: destRoot)
            } else {
                makeLinkedFilesInvalid(srcRoot, destRoot: destRoot)
                result = DeleteResult(srcRoot: nil, destRoot: nil)
            }
        } catch {
            if informDelegate {
                delegate.fileManager(operationManager, addError: error, forItem: srcRoot)
            }
        }
        if informDelegate,
           let result,
           let srcRoot = result.srcRoot {
            delegate.fileManager(operationManager, updateForItem: srcRoot)
        }

        return result
    }

    private func makeLinkedFilesInvalid(
        _ srcRoot: CompareItem,
        destRoot: CompareItem
    ) {
        // srcRoot and destRoot now are both invalid files (eg they both no longer exist)
        // so we remove the folderStatus row and its visibleItem
        srcRoot.parent?.remove(child: srcRoot)
        destRoot.parent?.remove(child: destRoot)

        if let vi = srcRoot.visibleItem {
            srcRoot.parent?.visibleItem?.remove(vi)
        }
        if let vi = destRoot.visibleItem {
            destRoot.parent?.visibleItem?.remove(vi)
        }
    }

    private func makeFileOrphan(
        _ srcRoot: CompareItem,
        destRoot: CompareItem,
        parentDestCount: inout CompareSummary
    ) {
        srcRoot.path = nil
        srcRoot.setAttributes(nil, fileExtraOptions: [])
        srcRoot.linkedItem = destRoot
        srcRoot.linkedItemIsFolder(false)

        parentDestCount -= destRoot.summary
        parentDestCount.orphanFiles += 1
        destRoot.addOrphanFiles(1)
    }

    private func remove(item: CompareItem) throws {
        guard let path = item.path else {
            throw FolderManagerError.nilPath
        }
        #if __VD_FAKE_FS_OP__
            Logger.debug.info("Fake delete, no files are really deleted - \(path)")
        #else
            try fm.removeItem(atPath: path)
        #endif
    }
}
