//
//  RenameCompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

// swiftlint:disable function_parameter_count
class RenameCompareItem {
    let operationManager: FileOperationManager
    private let fm = FileManager.default
    private let delegate: FileOperationManagerDelegate

    init(operationManager: FileOperationManager) {
        self.operationManager = operationManager
        delegate = operationManager.delegate
    }

    func rename(
        srcRoot: CompareItem,
        toName: String
    ) {
        guard let srcUrl = srcRoot.toUrl(),
              srcRoot.isValidFile else {
            return
        }

        guard let volumeType = srcUrl.volumeType() else {
            operationManager.delegate.fileManager(
                operationManager,
                addError: FileError.unknownVolumeType,
                forItem: srcRoot
            )
            return
        }

        var srcCount = CompareSummary()
        var destCount = CompareSummary()

        _ = try? doRename(
            srcRoot,
            toName: toName,
            parentSrcCount: &srcCount,
            parentDestCount: &destCount,
            volumeType: volumeType
        )

        var parent = srcRoot.parent

        while let item = parent {
            item.addOlderFiles(srcCount.olderFiles)
            item.addChangedFiles(srcCount.changedFiles)
            item.addMatchedFiles(srcCount.matchedFiles)
            item.addOrphanFiles(srcCount.orphanFiles)

            if let destItem = item.linkedItem {
                destItem.addOlderFiles(destCount.olderFiles)
                destItem.addChangedFiles(destCount.changedFiles)
                destItem.addMatchedFiles(destCount.matchedFiles)
                destItem.addOrphanFiles(destCount.orphanFiles)
            }

            item.removeVisibleItems(filterConfig: operationManager.filterConfig)

            parent = item.parent
        }
    }

    @discardableResult
    func doRename(
        _ srcRoot: CompareItem,
        toName: String,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        volumeType _: String
    ) throws -> Bool {
        delegate.waitPause(for: operationManager)

        if !delegate.isRunning(operationManager) {
            return false
        }

        if !srcRoot.isValidFile {
            return true
        }
        let isFiltered = srcRoot.isFiltered || !srcRoot.isDisplayed
        if !operationManager.includesFiltered, isFiltered {
            return true
        }

        guard let srcUrl = srcRoot.toUrl() else {
            throw FolderManagerError.nilPath
        }

        guard let destRoot = srcRoot.linkedItem else {
            throw FolderManagerError.nilPath
        }

        let toPath = srcUrl
            .deletingLastPathComponent()
            .appendingPathComponent(toName)

        var renamedSrcRoot: CompareItem?

        do {
            try fm.moveItem(at: srcUrl, to: toPath)
            // search fileName on other side
            let fileIndex = destRoot.parent?.findChildFileNameIndex(
                toName,
                typeIsFile: srcRoot.isFile
            ) ?? NSNotFound

            if fileIndex == NSNotFound {
                renamedSrcRoot = insertOrphan(
                    srcRoot: srcRoot,
                    toPath: toPath,
                    parentCount: &parentSrcCount
                )
            } else {
                if let item = destRoot.parent?.child(at: fileIndex) {
                    renamedSrcRoot = align(
                        srcRoot: srcRoot,
                        toPath: toPath,
                        item: item,
                        index: fileIndex,
                        parentSrcCount: &parentSrcCount,
                        parentDestCount: &parentDestCount
                    )
                }
            }
            // all files now are orphans so decrement correctly parent counters
            parentDestCount.orphanFiles += destRoot.matchedFiles + destRoot.olderFiles + destRoot.changedFiles
            parentDestCount.matchedFiles -= destRoot.matchedFiles
            parentDestCount.olderFiles -= destRoot.olderFiles
            parentDestCount.changedFiles -= destRoot.changedFiles

            // must be called after duplicateAsOrphan because it resets
            // srcRoot's path and attrs
            destRoot.mark(asOrphan: true)

            if let parent = srcRoot.parent {
                parent.filterVisibleItems(
                    showFilteredFiles: operationManager.filterConfig.showFilteredFiles,
                    hideEmptyFolders: operationManager.filterConfig.hideEmptyFolders,
                    recursive: true
                )
            }

            // Start from renamedSrcRoot's parent because after rename both src and dest may be orphans
            // and displayFilters can require to remove them
            renamedSrcRoot?.parent?.removeVisibleItems(
                filterConfig: operationManager.filterConfig,
                recursive: true
            )
        } catch {
            delegate.fileManager(operationManager, addError: error, forItem: srcRoot)
        }
        delegate.fileManager(operationManager, updateForItem: srcRoot)

        return true
    }

    private func insertOrphan(
        srcRoot: CompareItem,
        toPath: URL,
        parentCount: inout CompareSummary
    ) -> CompareItem {
        // srcRoot and destRoot are both orphans
        parentCount.orphanFiles += srcRoot.matchedFiles + srcRoot.olderFiles + srcRoot.changedFiles
        parentCount.matchedFiles -= srcRoot.matchedFiles
        parentCount.olderFiles -= srcRoot.olderFiles
        parentCount.changedFiles -= srcRoot.changedFiles

        let renamedSrcRoot = srcRoot.duplicateAsOrphan(
            withPath: toPath.osPath,
            withParent: srcRoot.parent,
            fileExtraOptions: operationManager.filterConfig.fileExtraOptions,
            recursive: true
        )

        // find insertion point into parent
        let insertPoint = findInsertionPoint(in: srcRoot.parent, for: renamedSrcRoot)

        renamedSrcRoot.parent?.insert(child: renamedSrcRoot, at: insertPoint)
        if let linkedItem = renamedSrcRoot.linkedItem {
            linkedItem.parent?.insert(child: linkedItem, at: insertPoint)
        }

        return renamedSrcRoot
    }

    private func findInsertionPoint(in parent: CompareItem?, for item: CompareItem) -> Int {
        guard let parent else {
            return 0
        }

        var insertPoint = 0
        for child in parent.children {
            if let child = child.isValidFile ? child : child.linkedItem {
                let result = child.compare(forList: item, followSymLinks: false)
                if result == .orderedDescending {
                    break
                }
            }
            insertPoint += 1
        }
        return insertPoint
    }

    private func align(
        srcRoot: CompareItem,
        toPath: URL,
        item: CompareItem,
        index: Int,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary
    ) -> CompareItem {
        if srcRoot.isOrphanFolder || srcRoot.isOrphanFile {
            linkNewItem(
                srcRoot: srcRoot,
                toPath: toPath,
                item: item,
                index: index,
                parentSrcCount: &parentSrcCount,
                parentDestCount: &parentDestCount
            )
        } else {
            makeOrphan(
                srcRoot: srcRoot,
                toPath: toPath,
                item: item,
                index: index,
                parentSrcCount: &parentSrcCount,
                parentDestCount: &parentDestCount
            )
        }
    }

    private func linkNewItem(
        srcRoot: CompareItem,
        toPath: URL,
        item: CompareItem,
        index: Int,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary
    ) -> CompareItem {
        parentSrcCount.orphanFiles -= srcRoot.orphanFiles
        parentDestCount.orphanFiles -= item.orphanFiles

        let renamedSrcRoot = srcRoot.duplicateAsOrphan(
            withPath: toPath.osPath,
            withParent: srcRoot.parent,
            fileExtraOptions: operationManager.filterConfig.fileExtraOptions,
            recursive: true
        )

        renamedSrcRoot.linkedItem = item
        item.linkedItem = renamedSrcRoot
        operationManager.comparator.alignItem(
            renamedSrcRoot,
            rightRoot: item,
            alignConfig: AlignConfig(recursive: true, followSymLinks: operationManager.filterConfig.followSymLinks)
        )

        // TODO: expensive
        renamedSrcRoot.applyComparison(
            fileFilters: operationManager.filterConfig.predicate,
            comparator: operationManager.comparator,
            recursive: true
        )

        parentSrcCount.orphanFiles += renamedSrcRoot.orphanFiles
        parentSrcCount.matchedFiles += renamedSrcRoot.matchedFiles
        parentSrcCount.olderFiles += renamedSrcRoot.olderFiles
        parentSrcCount.changedFiles += renamedSrcRoot.changedFiles

        parentDestCount.orphanFiles += item.orphanFiles
        parentDestCount.matchedFiles += item.matchedFiles
        parentDestCount.olderFiles += item.olderFiles
        parentDestCount.changedFiles += item.changedFiles
        // TODO: memory leak on srcRoot.linkedItem and item.linkedItem
        // TODO: memory leak on replaced element
        renamedSrcRoot.parent?.replaceChild(at: index, with: renamedSrcRoot)

        return renamedSrcRoot
    }

    private func makeOrphan(
        srcRoot: CompareItem,
        toPath: URL,
        item: CompareItem,
        index: Int,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary
    ) -> CompareItem {
        // item is orphan so decrement parent
        // the comparison done below will recompute the new counters
        parentDestCount.orphanFiles -= item.orphanFiles

        // srcRoot and destRoot are both orphans
        parentSrcCount.orphanFiles += srcRoot.matchedFiles + srcRoot.olderFiles + srcRoot.changedFiles
        parentSrcCount.matchedFiles -= srcRoot.matchedFiles
        parentSrcCount.olderFiles -= srcRoot.olderFiles
        parentSrcCount.changedFiles -= srcRoot.changedFiles

        let renamedSrcRoot = srcRoot.duplicateAsOrphan(
            withPath: toPath.osPath,
            withParent: srcRoot.parent,
            fileExtraOptions: operationManager.filterConfig.fileExtraOptions,
            recursive: true
        )

        renamedSrcRoot.linkedItem = item
        item.linkedItem = renamedSrcRoot
        operationManager.comparator.alignItem(
            renamedSrcRoot,
            rightRoot: item,
            alignConfig: AlignConfig(recursive: true, followSymLinks: operationManager.filterConfig.followSymLinks)
        )

        parentSrcCount.orphanFiles -= renamedSrcRoot.orphanFiles

        // TODO: expensive
        renamedSrcRoot.applyComparison(
            fileFilters: operationManager.filterConfig.predicate,
            comparator: operationManager.comparator,
            recursive: true
        )

        parentSrcCount.orphanFiles += renamedSrcRoot.orphanFiles
        parentSrcCount.matchedFiles += renamedSrcRoot.matchedFiles
        parentSrcCount.olderFiles += renamedSrcRoot.olderFiles
        parentSrcCount.changedFiles += renamedSrcRoot.changedFiles

        parentDestCount.orphanFiles += item.orphanFiles
        parentDestCount.matchedFiles += item.matchedFiles
        parentDestCount.olderFiles += item.olderFiles
        parentDestCount.changedFiles += item.changedFiles

        // TODO: memory leak on replaced element
        renamedSrcRoot.parent?.replaceChild(at: index, with: renamedSrcRoot)

        return renamedSrcRoot
    }
}

// swiftlint:enable function_parameter_count
