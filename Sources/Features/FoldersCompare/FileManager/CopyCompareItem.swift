//
//  CopyCompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

import os.log

// swiftlint:disable function_parameter_count
class CopyCompareItem: NSObject {
    let operationManager: FileOperationManager
    private let fm = FileManager.default
    private let deleteCompareItem: DeleteCompareItem
    private(set) var bigFileSizeThreshold: UInt64
    private var bigFileManager: BigFileFileOperationManager

    init(
        operationManager: FileOperationManager,
        bigFileSizeThreshold: UInt64
    ) {
        self.operationManager = operationManager
        self.bigFileSizeThreshold = bigFileSizeThreshold
        deleteCompareItem = DeleteCompareItem(operationManager: operationManager)
        bigFileManager = BigFileFileOperationManager(
            operationManager,
            delegate: operationManager.delegate
        )
    }

    func copy(
        srcRoot: CompareItem,
        srcBaseDir: URL,
        destBaseDir: URL
    ) {
        guard srcRoot.isValidFile else {
            return
        }
        guard let volumeType = srcBaseDir.volumeType() else {
            operationManager.delegate.fileManager(
                operationManager,
                addError: FileError.unknownVolumeType,
                forItem: srcRoot
            )
            return
        }
        var srcCount = CompareSummary()
        var destCount = CompareSummary()

        doCopy(
            srcRoot,
            srcBaseDir: srcBaseDir,
            destBaseDir: destBaseDir,
            parentSrcCount: &srcCount,
            parentDestCount: &destCount,
            volumeType: volumeType
        )

        var parent = srcRoot.parent
        while let item = parent,
              let fsUrl = item.toUrl() {
            let destFullPath = URL.buildDestinationPath(fsUrl, nil, srcBaseDir, destBaseDir)

            item.addOlderFiles(-srcCount.olderFiles)
            item.addChangedFiles(-srcCount.changedFiles)
            item.addOrphanFiles(-srcCount.orphanFiles)
            // matched file count increases
            item.addMatchedFiles(srcCount.matchedFiles)
            if item.isOrphanFolder {
                item.addOrphanFolders(-1)
            }
            item.addMismatchingTags(-srcCount.mismatchingTags)
            item.addMismatchingLabels(-srcCount.mismatchingLabels)

            if let destItem = item.linkedItem,
               let attrs = try? fm.attributesOfItem(atPath: destFullPath.osPath) {
                destItem.path = destFullPath.osPath
                destItem.setAttributes(attrs, fileExtraOptions: operationManager.filterConfig.fileExtraOptions)
                destItem.addOlderFiles(-destCount.olderFiles)
                destItem.addChangedFiles(-destCount.changedFiles)
                destItem.addOrphanFiles(-destCount.orphanFiles)
                // matched file count increases
                destItem.addMatchedFiles(destCount.matchedFiles)
                destItem.addSubfoldersSize(destCount.subfoldersSize)

                destItem.addMismatchingTags(-destCount.mismatchingTags)
                destItem.addMismatchingLabels(-destCount.mismatchingLabels)
            }

            item.removeVisibleItems(filterConfig: operationManager.filterConfig)

            parent = item.parent
        }
    }

    @discardableResult
    private func doCopy(
        _ srcRoot: CompareItem,
        srcBaseDir: URL,
        destBaseDir: URL,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        volumeType: String
    ) -> Bool {
        let delegate = operationManager.delegate

        delegate.waitPause(for: operationManager)

        guard delegate.isRunning(operationManager) else {
            return false
        }

        guard srcRoot.isValidFile else {
            return true
        }
        let isFiltered = srcRoot.isFiltered || !srcRoot.isDisplayed
        if !operationManager.includesFiltered, isFiltered {
            return true
        }
        guard let srcRootPath = srcRoot.path,
              let destRoot = srcRoot.linkedItem else {
            return true
        }

        var retVal = true
        var destFullPath = srcRoot.buildDestinationPath(from: srcBaseDir, to: destBaseDir)

        do {
            let srcAttrs = try fm.attributesOfItem(atPath: srcRootPath)
            if srcRoot.isFile {
                var skipFile = false
                try copySingleFile(
                    srcRoot,
                    destRoot: destRoot,
                    srcBaseDir: srcBaseDir,
                    destBaseDir: destBaseDir,
                    parentSrcCount: &parentSrcCount,
                    parentDestCount: &parentDestCount,
                    skipFile: &skipFile,
                    volumeType: volumeType
                )
                if skipFile {
                    return true
                }
            } else {
                try operationManager.createDestinationDirectory(
                    srcRoot,
                    destRoot: destRoot,
                    srcBaseDir: srcBaseDir,
                    destBaseDir: destBaseDir,
                    destFullPath: destFullPath
                )
                retVal = copySubfolders(
                    srcRoot,
                    destRoot: destRoot,
                    srcBaseDir: srcBaseDir,
                    destBaseDir: destBaseDir,
                    destFullPath: &destFullPath,
                    parentSrcCount: &parentSrcCount,
                    parentDestCount: &parentDestCount,
                    volumeType: volumeType
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
        return retVal
    }

    func copySingleFile(
        _ srcRoot: CompareItem,
        destRoot: CompareItem,
        srcBaseDir: URL,
        destBaseDir: URL,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        skipFile: inout Bool,
        volumeType: String
    ) throws {
        skipFile = false
        guard let srcRootPath = srcRoot.path else {
            return
        }
        let delegate = operationManager.delegate
        var srcCount = srcRoot.summary
        var destCount = destRoot.summary
        var fileSize: Int64 = 0
        do {
            let srcAttrs = try fm.attributesOfItem(atPath: srcRootPath)
            let destFullPath = srcRoot.buildDestinationPath(from: srcBaseDir, to: destBaseDir)
            var destAttrs: [FileAttributeKey: Any]?
            var destError: NSError?
            do {
                let pathAttrs = try fm.attributesOfItem(atPath: destFullPath.osPath)
                destAttrs = pathAttrs
                fileSize = pathAttrs[.size] as? Int64 ?? 0
            } catch let error as NSError {
                if error.code != NSFileReadNoSuchFileError {
                    destError = error
                }
            }
            if !delegate.fileManager(
                operationManager,
                canReplaceFromPath: srcRootPath,
                fromAttrs: srcAttrs,
                toPath: destFullPath.osPath,
                toAttrs: destAttrs
            ) {
                skipFile = true
                return
            }
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
            if let destError {
                throw destError
            }
            try copyItem(
                srcRoot,
                isBigFile: srcRoot.fileSize >= bigFileSizeThreshold,
                destFullPath: destFullPath,
                lastPathTimestamps: lastPathTimestamps,
                volumeType: volumeType
            )
        } catch {
            delegate.fileManager(operationManager, addError: error, forItem: srcRoot)
        }

        #if DEBUG && __VD_SLOW_OP__
            simulateSlowOperation("copy")
        #endif

        srcRoot.addMatchedFiles(1)
        srcRoot.updateMetadata(
            with: &parentSrcCount,
            fileObjectCount: &srcCount
        )

        destRoot.addMatchedFiles(1)
        destRoot.updateMetadata(
            with: &parentDestCount,
            fileObjectCount: &destCount
        )

        if srcCount.matchedFiles == 0 {
            parentSrcCount += srcCount
            parentDestCount += destCount
            parentSrcCount.matchedFiles += 1
            parentDestCount.matchedFiles += 1
        }
        parentDestCount.subfoldersSize += srcRoot.fileSize - fileSize
        delegate.fileManager(operationManager, updateForItem: srcRoot)
    }

    func copyItem(
        _ srcRoot: CompareItem,
        isBigFile: Bool,
        destFullPath: URL,
        lastPathTimestamps: PathTimestamps?,
        volumeType: String
    ) throws {
        guard let srcUrl = srcRoot.toUrl() else {
            return
        }
        #if DEBUG && __VD_FAKE_FS_OP__
            Logger.debug.info("Fake copy, no files are really copied - \(path.localPath)")
        #else
            if isBigFile {
                try bigFileManager.copy(srcRoot, destFullPath: destFullPath.osPath)
            } else {
                try fm.copyItem(at: srcUrl, to: destFullPath)
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

    func copySubfolders(
        _ srcRoot: CompareItem,
        destRoot _: CompareItem,
        srcBaseDir: URL,
        destBaseDir: URL,
        destFullPath: inout URL,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        volumeType: String
    ) -> Bool {
        var srcCount = CompareSummary()
        var destCount = CompareSummary()
        var retVal = true

        for item in srcRoot.children {
            // swiftlint:disable:next for_where
            if !doCopy(
                item,
                srcBaseDir: srcBaseDir,
                destBaseDir: destBaseDir,
                parentSrcCount: &srcCount,
                parentDestCount: &destCount,
                volumeType: volumeType
            ) {
                retVal = false
                break
            }
        }
        do {
            try srcRoot.copyMetadata(toPath: &destFullPath)
        } catch {
            operationManager.delegate.fileManager(operationManager, addError: error, forItem: srcRoot)
        }

        if srcRoot.isOrphanFolder {
            srcRoot.addOrphanFolders(-1)
        }
        srcRoot.addOlderFiles(-srcCount.olderFiles)
        srcRoot.addChangedFiles(-srcCount.changedFiles)
        srcRoot.addOrphanFiles(-srcCount.orphanFiles)
        // matched file count increases
        srcRoot.addMatchedFiles(srcCount.matchedFiles)

        parentSrcCount += srcCount
        var srcCountDummy = CompareSummary()
        srcRoot.updateMetadata(with: &parentSrcCount, fileObjectCount: &srcCountDummy)

        if let srcRootLinked = srcRoot.linkedItem {
            srcRootLinked.addOlderFiles(-destCount.olderFiles)
            srcRootLinked.addChangedFiles(-destCount.changedFiles)
            srcRootLinked.addOrphanFiles(-destCount.orphanFiles)
            srcRootLinked.addSubfoldersSize(destCount.subfoldersSize)

            // matched file count increases
            srcRootLinked.addMatchedFiles(destCount.matchedFiles)

            parentDestCount += destCount
            var destCountDummy = CompareSummary()
            srcRootLinked.updateMetadata(with: &parentDestCount, fileObjectCount: &destCountDummy)
        }
        return retVal
    }

    func copyAttributes(
        _ srcRoot: CompareItem,
        destRoot: CompareItem,
        attributes: [FileAttributeKey: Any],
        destFullPath: URL,
        volumeType: String
    ) throws {
        guard let fsSrcPath = (srcRoot.path as? NSString)?.fileSystemRepresentation else {
            throw FolderManagerError.nilPath
        }
        let fsDestPath = (destFullPath.osPath as NSString).fileSystemRepresentation

        copyfile(fsSrcPath, fsDestPath, nil, copyfile_flags_t(COPYFILE_METADATA))

        // set the timestamps at the end so we are sure they are not 'overwritten'
        // For example modification date for folders changes after a file is copied into it
        try fm.setFileAttributes(
            operationManager.timestampAttributesFrom(attributes),
            ofItemAtPath: destFullPath,
            volumeType: volumeType
        )
        // the delete above reset path and file to nil
        // here we assign again the copied values
        let destAttrs = try fm.attributesOfItem(atPath: destFullPath.osPath)

        destRoot.path = destFullPath.osPath
        destRoot.setAttributes(destAttrs, fileExtraOptions: operationManager.filterConfig.fileExtraOptions)

        srcRoot.removeVisibleItems(filterConfig: operationManager.filterConfig)
    }
}

// swiftlint:enable function_parameter_count
