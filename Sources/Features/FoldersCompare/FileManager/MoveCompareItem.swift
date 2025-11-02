//
//  MoveCompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

// swiftlint:disable function_parameter_count file_length
public class MoveCompareItem: NSObject {
    let operationManager: FileOperationManager
    private let fm = FileManager.default
    private let deleteCompareItem: DeleteCompareItem
    private(set) var bigFileSizeThreshold: UInt64
    private let delegate: FileOperationManagerDelegate
    private var bigFileManager: BigFileFileOperationManager

    init(
        operationManager: FileOperationManager,
        bigFileSizeThreshold: UInt64
    ) {
        self.operationManager = operationManager
        self.bigFileSizeThreshold = bigFileSizeThreshold

        deleteCompareItem = DeleteCompareItem(operationManager: operationManager)
        delegate = operationManager.delegate
        bigFileManager = BigFileFileOperationManager(
            operationManager,
            delegate: operationManager.delegate
        )
    }

    public func move(
        srcRoot: CompareItem,
        srcBaseDir: URL,
        destBaseDir: URL
    ) {
        guard srcRoot.isValidFile else {
            return
        }

        guard let volumeType = destBaseDir.volumeType() else {
            delegate.fileManager(
                operationManager,
                addError: FileError.unknownVolumeType,
                forItem: srcRoot
            )
            return
        }

        var srcCount = CompareSummary()
        var destCount = CompareSummary()

        _ = try? doMove(
            srcRoot,
            srcBaseDir: srcBaseDir,
            destBaseDir: destBaseDir,
            parentSrcCount: &srcCount,
            parentDestCount: &destCount,
            volumeType: volumeType
        )

        var parent = srcRoot.parent
        while let item = parent,
              let itemUrl = item.toUrl() {
            let destUrl = URL.buildDestinationPath(itemUrl, nil, srcBaseDir, destBaseDir)
            let destFullPath = destUrl.osPath

            item.addOlderFiles(-srcCount.olderFiles)
            item.addChangedFiles(-srcCount.changedFiles)
            item.addOrphanFiles(-srcCount.orphanFiles)
            item.addMatchedFiles(-srcCount.matchedFiles)
            item.addSubfoldersSize(-srcCount.subfoldersSize)

            item.addMismatchingTags(-srcCount.mismatchingTags)
            item.addMismatchingLabels(-srcCount.mismatchingLabels)

            if let destItem = item.linkedItem,
               let attrs = try? fm.attributesOfItem(atPath: destFullPath) {
                destItem.path = destFullPath
                destItem.setAttributes(attrs, fileExtraOptions: operationManager.filterConfig.fileExtraOptions)
                destItem.addOlderFiles(-destCount.olderFiles)
                destItem.addChangedFiles(-destCount.changedFiles)
                destItem.addOrphanFiles(-destCount.orphanFiles)
                destItem.addMatchedFiles(-destCount.matchedFiles)
                destItem.addSubfoldersSize(-destCount.subfoldersSize)

                destItem.addMismatchingTags(-destCount.mismatchingTags)
                destItem.addMismatchingLabels(-destCount.mismatchingLabels)
            }

            item.removeVisibleItems(filterConfig: operationManager.filterConfig)

            parent = item.parent
        }
    }

    @discardableResult
    func doMove(
        _ srcRoot: CompareItem,
        srcBaseDir: URL,
        destBaseDir: URL,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        volumeType: String
    ) throws -> Bool {
        delegate.waitPause(for: operationManager)

        guard delegate.isRunning(operationManager) else {
            return false
        }

        guard srcRoot.isValidFile else {
            return true
        }

        guard let destRoot = srcRoot.linkedItem else {
            throw FolderManagerError.nilPath
        }

        let isFiltered = srcRoot.isFiltered || !srcRoot.isDisplayed
        if !operationManager.includesFiltered, isFiltered {
            return true
        }

        guard let srcRootPath = srcRoot.path else {
            throw FolderManagerError.nilPath
        }

        var destAttrs: [FileAttributeKey: Any]?
        var destFullPath = srcRoot.buildDestinationPath(from: srcBaseDir, to: destBaseDir)

        do {
            let srcAttrs = try fm.attributesOfItem(atPath: srcRootPath)

            if srcRoot.isFile {
                do {
                    destAttrs = try fm.attributesOfItem(atPath: destFullPath.osPath)
                } catch {}
                if !delegate.fileManager(
                    operationManager,
                    canReplaceFromPath: srcRootPath,
                    fromAttrs: srcAttrs,
                    toPath: destFullPath.osPath,
                    toAttrs: destAttrs
                ) {
                    // skip this file
                    return true
                }
                try moveSingleFile(
                    srcRoot,
                    destRoot: destRoot,
                    srcAttrs: srcAttrs,
                    destAttrs: destAttrs,
                    destFullPath: destFullPath,
                    srcBaseDir: srcBaseDir,
                    destBaseDir: destBaseDir,
                    parentSrcCount: &parentSrcCount,
                    parentDestCount: &parentDestCount,
                    volumeType: volumeType
                )
            } else {
                try operationManager.createDestinationDirectory(
                    srcRoot,
                    destRoot: destRoot,
                    srcBaseDir: srcBaseDir,
                    destBaseDir: destBaseDir,
                    destFullPath: destFullPath
                )
                try moveSubfolders(
                    srcRoot,
                    destRoot: destRoot,
                    srcBaseDir: srcBaseDir,
                    destBaseDir: destBaseDir,
                    destFullPath: &destFullPath,
                    parentSrcCount: &parentSrcCount,
                    parentDestCount: &parentDestCount,
                    volumeType: volumeType
                )

                try deleteSourceDirectory(
                    srcRoot,
                    destRoot: destRoot,
                    attributes: srcAttrs,
                    destFullPath: destFullPath
                )
            }
            try copyAttributes(
                srcRoot,
                destRoot: destRoot,
                attributes: srcAttrs,
                destFullPath: destFullPath,
                volumeType: volumeType
            )
        } catch {
            delegate.fileManager(operationManager, addError: error, forItem: srcRoot)
        }
        return true
    }

    private func moveSingleFile(
        _ srcRoot: CompareItem,
        destRoot: CompareItem,
        srcAttrs _: [FileAttributeKey: Any],
        destAttrs: [FileAttributeKey: Any]?,
        destFullPath: URL,
        srcBaseDir: URL,
        destBaseDir: URL,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        volumeType: String
    ) throws {
        var srcCount = srcRoot.summary
        var destCount = destRoot.summary

        do {
            let lastPathTimestamps = try createDirectory(
                atPath: destBaseDir,
                srcBaseDir: srcBaseDir,
                namesFrom: srcRoot,
                options: operationManager.comparator.options.directoryOptions
            )
            if let destAttrs {
                destRoot.path = destFullPath.osPath
                destRoot.setAttributes(destAttrs, fileExtraOptions: operationManager.filterConfig.fileExtraOptions)
                deleteCompareItem.doDelete(
                    destRoot,
                    baseDir: destBaseDir,
                    informDelegate: false
                )
            }
            delegate.fileManager(operationManager, initForItem: srcRoot)

            try moveItem(
                srcRoot,
                isBigFile: srcRoot.fileSize >= bigFileSizeThreshold,
                destFullPath: destFullPath,
                lastPathTimestamps: lastPathTimestamps,
                volumeType: volumeType
            )
            #if DEBUG && __VD_SLOW_OP__
                simulateSlowOperation("move")
            #endif
            updateParentCountersAfterMoveFile(
                srcRoot,
                destRoot: destRoot,
                destAttrs: destAttrs,
                parentSrcCount: &parentSrcCount,
                parentDestCount: &parentDestCount,
                srcCount: &srcCount,
                destCount: &destCount
            )
        } catch {
            delegate.fileManager(operationManager, addError: error, forItem: srcRoot)
        }
        delegate.fileManager(operationManager, updateForItem: srcRoot)
    }

    func updateParentCountersAfterMoveFile(
        _ srcRoot: CompareItem,
        destRoot: CompareItem,
        destAttrs: [FileAttributeKey: Any]?,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        srcCount: inout CompareSummary,
        destCount: inout CompareSummary
    ) {
        let srcSize = srcRoot.fileSize
        let destSize: Int64 = if let destAttrs, let size = (destAttrs[.size] as? NSNumber) {
            size.int64Value
        } else {
            0
        }

        parentDestCount.olderFiles += destCount.olderFiles
        parentDestCount.changedFiles += destCount.changedFiles
        parentDestCount.matchedFiles += destCount.matchedFiles
        parentDestCount.subfoldersSize -= srcSize - destSize
        parentDestCount.orphanFiles -= 1

        parentSrcCount.olderFiles += srcCount.olderFiles
        parentSrcCount.changedFiles += srcCount.changedFiles
        parentSrcCount.matchedFiles += srcCount.matchedFiles
        parentSrcCount.subfoldersSize += srcSize
        parentSrcCount.orphanFiles += srcCount.orphanFiles

        // set all counters on destRoot to 0 except 'orphan' set to 1
        // because it's an orphan file
        destRoot.addOrphanFiles(1)
        destRoot.updateMetadata(
            with: &parentDestCount,
            fileObjectCount: &destCount
        )

        srcRoot.updateMetadata(
            with: &parentSrcCount,
            fileObjectCount: &srcCount
        )

        srcRoot.invalidate()
        srcRoot.isFiltered = false
    }

    func moveItem(
        _ srcRoot: CompareItem,
        isBigFile: Bool,
        destFullPath: URL,
        lastPathTimestamps: PathTimestamps?,
        volumeType: String
    ) throws {
        #if DEBUG && __VD_FAKE_FS_OP__
            Logger.debug.info("Fake move, no files are really moved - \(srcRoot.path)")
        #else
            guard let url = srcRoot.toUrl() else {
                throw FolderManagerError.nilPath
            }
            if isBigFile {
                try bigFileManager.move(srcRoot, destFullPath: destFullPath.osPath)
            } else {
                try fm.moveItem(at: url, to: destFullPath)
            }
            if let lastPathTimestamps {
                try fm.setFileAttributes(
                    lastPathTimestamps.timestamps,
                    ofItemAtPath: destFullPath.deletingLastPathComponent(),
                    volumeType: volumeType
                )
            }
        #endif
    }

    func moveSubfolders(
        _ srcRoot: CompareItem,
        destRoot: CompareItem,
        srcBaseDir: URL,
        destBaseDir: URL,
        destFullPath: inout URL,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        volumeType: String
    ) throws {
        var srcCount = CompareSummary()
        var destCount = CompareSummary()

        do {
            // interate in reverse order because the collection changes while running
            for item in srcRoot.children.reversed() {
                // swiftlint:disable:next for_where
                if try doMove(
                    item,
                    srcBaseDir: srcBaseDir,
                    destBaseDir: destBaseDir,
                    parentSrcCount: &srcCount,
                    parentDestCount: &destCount,
                    volumeType: volumeType
                ) == false {
                    break
                }
            }
        } catch {}

        do {
            try srcRoot.copyMetadata(toPath: &destFullPath)
        } catch {
            delegate.fileManager(operationManager, addError: error, forItem: srcRoot)
        }

        srcRoot.addOlderFiles(-srcCount.olderFiles)
        srcRoot.addChangedFiles(-srcCount.changedFiles)
        srcRoot.addOrphanFiles(-srcCount.orphanFiles)
        srcRoot.addMatchedFiles(-srcCount.matchedFiles)
        srcRoot.addSubfoldersSize(-srcCount.subfoldersSize)
        parentSrcCount += srcCount
        var dummySrcCount = CompareSummary()
        srcRoot.updateMetadata(
            with: &parentSrcCount,
            fileObjectCount: &dummySrcCount
        )

        destRoot.addOlderFiles(-destCount.olderFiles)
        destRoot.addChangedFiles(-destCount.changedFiles)
        destRoot.addOrphanFiles(-destCount.orphanFiles)
        destRoot.addMatchedFiles(-destCount.matchedFiles)
        destRoot.addSubfoldersSize(-destCount.subfoldersSize)
        parentDestCount += destCount
        var dummyDestCount = CompareSummary()
        destRoot.updateMetadata(
            with: &parentDestCount,
            fileObjectCount: &dummyDestCount
        )
    }

    private func deleteSourceDirectory(
        _ srcRoot: CompareItem,
        destRoot: CompareItem,
        attributes _: [FileAttributeKey: Any],
        destFullPath: URL
    ) throws {
        guard operationManager.canRemoveDirectory(srcRoot) else {
            return
        }

        guard let srcPath = srcRoot.path else {
            throw FolderManagerError.nilPath
        }
        let fsSrcPath = (srcPath as NSString).fileSystemRepresentation
        let fsDestPath = (destFullPath.osPath as NSString).fileSystemRepresentation

        copyfile(fsSrcPath, fsDestPath, nil, copyfile_flags_t(COPYFILE_METADATA))

        do {
            try fm.removeItem(atPath: srcPath)
        } catch {
            delegate.fileManager(operationManager, addError: error, forItem: srcRoot)
        }
        if srcRoot.isOrphanFolder {
            srcRoot.addOrphanFolders(-1)
            srcRoot.linkedItem?.addOrphanFolders(1)
        } else {
            srcRoot.linkedItem?.addOrphanFolders(1)
        }
        srcRoot.invalidate()

        // refresh isFolderObject
        srcRoot.linkedItemIsFolder(true)

        // destRoot is orphan set to default type
        destRoot.type = .orphan
    }

    func copyAttributes(
        _ srcRoot: CompareItem,
        destRoot: CompareItem,
        attributes: [FileAttributeKey: Any]?,
        destFullPath: URL,
        volumeType: String
    ) throws {
        // set the timestamps at the end so we are sure they are not 'overwritten'
        // For example modification date for folders changes after a file is copied into it
        if let attributes {
            try fm.setFileAttributes(
                operationManager.timestampAttributesFrom(attributes),
                ofItemAtPath: destFullPath,
                volumeType: volumeType
            )
        }
        // update file information after move
        destRoot.path = destFullPath.osPath
        destRoot.setAttributes(try? FileManager.default.attributesOfItem(atPath: destFullPath.osPath), fileExtraOptions: operationManager.filterConfig.fileExtraOptions)

        if destRoot.isFiltered,
           let filter = operationManager.filterConfig.predicate {
            // check if file is yet filtered after moving
            destRoot.isFiltered = destRoot.evaluate(filter: filter)
        }

        srcRoot.removeVisibleItems(filterConfig: operationManager.filterConfig)
    }
}

// swiftlint:enable function_parameter_count file_length
