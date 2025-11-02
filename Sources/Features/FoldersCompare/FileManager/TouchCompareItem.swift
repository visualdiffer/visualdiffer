//
//  TouchCompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

// swiftlint:disable function_parameter_count
class TouchCompareItem {
    let operationManager: FileOperationManager
    private let fm = FileManager.default
    private let delegate: FileOperationManagerDelegate

    init(operationManager: FileOperationManager) {
        self.operationManager = operationManager
        delegate = operationManager.delegate
    }

    func touch(
        srcRoot: CompareItem,
        includeSubfolders: Bool,
        touchDate: Date?
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
        let useComparator = operationManager.comparator.options.contains(.timestamp)

        doTouch(
            srcRoot,
            attrs: dateAttributes(touchDate),
            includeSubfolders: includeSubfolders,
            comparator: useComparator ? operationManager.comparator : nil,
            parentSrcCount: &srcCount,
            parentDestCount: &destCount,
            volumeType: volumeType
        )

        if useComparator {
            var parent = srcRoot.parent

            while let item = parent {
                item.addOlderFiles(srcCount.olderFiles)
                item.addChangedFiles(srcCount.changedFiles)
                item.addMatchedFiles(srcCount.matchedFiles)

                if let destItem = item.linkedItem {
                    destItem.addOlderFiles(destCount.olderFiles)
                    destItem.addChangedFiles(destCount.changedFiles)
                    destItem.addMatchedFiles(destCount.matchedFiles)
                }

                item.removeVisibleItems(filterConfig: operationManager.filterConfig)

                parent = item.parent
            }
        }
    }

    private func dateAttributes(_ date: Date?) -> [FileAttributeKey: Any]? {
        guard let date else {
            return nil
        }
        return [.modificationDate: date]
    }

    @discardableResult
    private func doTouch(
        _ srcRoot: CompareItem,
        attrs: [FileAttributeKey: Any]?,
        includeSubfolders: Bool,
        comparator: ItemComparator?,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary,
        volumeType: String
    ) -> Bool {
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
        guard let linkedItem = srcRoot.linkedItem else {
            return true
        }
        guard let dateDict = buildTouchDateAttributes(attrs: attrs, item: linkedItem) else {
            return true
        }

        guard let srcRootPath = srcRoot.path else {
            return true
        }
        delegate.fileManager(operationManager, initForItem: srcRoot)
        do {
            try fm.setFileAttributes(
                dateDict,
                ofItemAtPath: srcRootPath,
                volumeType: volumeType
            )
            #if DEBUG && __VD_SLOW_OP__
                simulateSlowOperation("touch")
            #endif
            let attrs = try fm.attributesOfItem(atPath: srcRootPath)
            srcRoot.setAttributes(attrs, fileExtraOptions: operationManager.filterConfig.fileExtraOptions)
            updateFileCounters(srcRoot, comparator, &parentSrcCount, &parentDestCount)
        } catch {
            delegate.fileManager(operationManager, addError: error, forItem: srcRoot)
        }
        delegate.fileManager(operationManager, updateForItem: srcRoot)

        touchFolders(
            srcRoot,
            volumeType: volumeType,
            attrs: attrs,
            includeSubfolders: includeSubfolders,
            comparator: comparator,
            parentSrcCount: &parentSrcCount,
            parentDestCount: &parentDestCount
        )

        srcRoot.removeVisibleItems(filterConfig: operationManager.filterConfig)

        return true
    }

    private func buildTouchDateAttributes(
        attrs: [FileAttributeKey: Any]?,
        item: CompareItem
    ) -> [FileAttributeKey: Any]? {
        if attrs != nil {
            return attrs
        }
        if item.isValidFile,
           let itemDate = item.fileModificationDate {
            return [.modificationDate: itemDate]
        }
        return nil
    }

    private func updateFileCounters(
        _ item: CompareItem,
        _ comparator: ItemComparator?,
        _ parentSrcCount: inout CompareSummary,
        _ parentDestCount: inout CompareSummary
    ) {
        guard item.isFile,
              let linkedItem = item.linkedItem else {
            return
        }

        var srcCount = CompareSummary()
        var destCount = CompareSummary()

        srcCount.olderFiles -= item.olderFiles
        srcCount.changedFiles -= item.changedFiles
        srcCount.matchedFiles -= item.matchedFiles

        destCount.olderFiles -= linkedItem.olderFiles
        destCount.changedFiles -= linkedItem.changedFiles
        destCount.matchedFiles -= linkedItem.matchedFiles

        comparator?.compare(item, linkedItem)
        applyFilters(item, linkedItem)
        removeFiltered(item, linkedItem)

        srcCount.olderFiles += item.olderFiles
        srcCount.changedFiles += item.changedFiles
        srcCount.matchedFiles += item.matchedFiles

        destCount.olderFiles += linkedItem.olderFiles
        destCount.changedFiles += linkedItem.changedFiles
        destCount.matchedFiles += linkedItem.matchedFiles

        parentSrcCount += srcCount
        parentDestCount += destCount
    }

    private func applyFilters(
        _ lhs: CompareItem,
        _ rhs: CompareItem
    ) {
        guard let fileFilters = operationManager.filterConfig.predicate else {
            return
        }
        let isFiltered = lhs.evaluate(filter: fileFilters) || rhs.evaluate(filter: fileFilters)
        lhs.isFiltered = isFiltered
        rhs.isFiltered = isFiltered
    }

    private func removeFiltered(
        _ lhs: CompareItem,
        _ rhs: CompareItem
    ) {
        guard !operationManager.filterConfig.showFilteredFiles, lhs.isFiltered else {
            return
        }
        if let parentVI = lhs.parent?.visibleItem,
           let vi = lhs.visibleItem {
            parentVI.remove(vi)
        }
        if let parentVI = rhs.parent?.visibleItem,
           let vi = rhs.visibleItem {
            parentVI.remove(vi)
        }
    }

    @discardableResult
    private func touchFolders(
        _ srcRoot: CompareItem,
        volumeType: String,
        attrs: [FileAttributeKey: Any]?,
        includeSubfolders: Bool,
        comparator: ItemComparator?,
        parentSrcCount: inout CompareSummary,
        parentDestCount: inout CompareSummary
    ) -> Bool {
        guard includeSubfolders, srcRoot.isFolder else {
            return true
        }
        var srcCount = CompareSummary()
        var destCount = CompareSummary()
        var retVal = true

        for item in srcRoot.children {
            // swiftlint:disable:next for_where
            if !doTouch(
                item,
                attrs: attrs,
                includeSubfolders: includeSubfolders,
                comparator: comparator,
                parentSrcCount: &srcCount,
                parentDestCount: &destCount,
                volumeType: volumeType
            ) {
                retVal = false
                break
            }
        }
        srcRoot.addOlderFiles(srcCount.olderFiles)
        srcRoot.addChangedFiles(srcCount.changedFiles)
        srcRoot.addMatchedFiles(srcCount.matchedFiles)
        parentSrcCount += srcCount

        if let linkedItem = srcRoot.linkedItem {
            linkedItem.addOlderFiles(destCount.olderFiles)
            linkedItem.addChangedFiles(destCount.changedFiles)
            linkedItem.addMatchedFiles(destCount.matchedFiles)
            parentDestCount += destCount
        }

        return retVal
    }
}

// swiftlint:enable function_parameter_count
