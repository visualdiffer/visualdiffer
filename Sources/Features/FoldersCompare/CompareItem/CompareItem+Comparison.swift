//
//  CompareItem+Comparison.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension CompareItem {
    func compareInfo(
        leftOrphanFiles: inout [CompareItem],
        rightOrphanFiles: inout [CompareItem],
        matchesFiles: inout [CompareItem],
        newerLeftFiles: inout [CompareItem],
        newerRightFiles: inout [CompareItem]
    ) {
        for item in children {
            if item.isFiltered {
                continue
            }
            if item.isFolder {
                item.compareInfo(
                    leftOrphanFiles: &leftOrphanFiles,
                    rightOrphanFiles: &rightOrphanFiles,
                    matchesFiles: &matchesFiles,
                    newerLeftFiles: &newerLeftFiles,
                    newerRightFiles: &newerRightFiles
                )
            } else {
                if let linkedItem = item.linkedItem {
                    if item.orphanFiles > 0 {
                        leftOrphanFiles.append(item)
                    } else if linkedItem.orphanFiles > 0 {
                        rightOrphanFiles.append(linkedItem)
                    } else if item.matchedFiles > 0 {
                        matchesFiles.append(item)
                    } else if item.changedFiles > 0, linkedItem.olderFiles > 0 {
                        newerLeftFiles.append(item)
                    } else if linkedItem.changedFiles > 0, item.olderFiles > 0 {
                        newerRightFiles.append(linkedItem)
                    } else {
                        newerLeftFiles.append(item)
                    }
                }
            }
        }
    }

    func applyComparison(
        fileFilters: NSPredicate?,
        comparator: ItemComparator?,
        recursive: Bool
    ) {
        guard let srcRight = linkedItem else {
            return
        }
        var leftFileCount = CompareSummary()
        var rightFileCount = CompareSummary()

        var children: [CompareItem]

        if isFile {
            children = [self]
        } else {
            children = self.children
            leftFileCount.mismatchingFolderMetadata = mismatchingFolderMetadata
            rightFileCount.mismatchingFolderMetadata = srcRight.mismatchingFolderMetadata
        }

        for left in children {
            guard let right = left.linkedItem else {
                continue
            }
            let isFiltered = isFiltered(
                leftItem: left,
                rightItem: right,
                fileFilters: fileFilters
            )

            if left.isFolder {
                if recursive {
                    left.applyComparison(
                        fileFilters: fileFilters,
                        comparator: comparator,
                        recursive: true
                    )
                }
            }
            if isFiltered {
                left.setSummary(CompareSummary())
                right.setSummary(CompareSummary())
                left.type = .orphan
                right.type = .orphan
            }
            if !isFiltered, let comparator {
                comparator.compare(left, right)
            }

            leftFileCount += left.summary
            rightFileCount += right.summary
            leftFileCount.subfoldersSize += left.fileSize
            rightFileCount.subfoldersSize += right.fileSize

            left.isFiltered = isFiltered
            right.isFiltered = isFiltered
        }
        setSummary(leftFileCount)
        srcRight.setSummary(rightFileCount)
    }

    private func isFiltered(
        leftItem: CompareItem,
        rightItem: CompareItem,
        fileFilters: NSPredicate?
    ) -> Bool {
        if let parent = leftItem.parent, parent.isFiltered {
            return true
        }
        if let fileFilters {
            return leftItem.evaluate(filter: fileFilters) || rightItem.evaluate(filter: fileFilters)
        }
        return false
    }

    func determineFileTypeWhen(
        followSymLinks: Bool,
        isFile: inout Bool,
        isFolder: inout Bool
    ) {
        if self.isFile {
            isFile = true
        } else if self.isFolder {
            if !followSymLinks, isSymbolicLink {
                isFile = true
            } else {
                isFolder = true
            }
        }
    }

    func compare(
        _ other: CompareItem,
        followSymLinks: Bool,
        comparator: CompareItemComparison
    ) -> ComparisonResult {
        var isFile1 = false
        var isFile2 = false
        var isFolder1 = false
        var isFolder2 = false

        determineFileTypeWhen(followSymLinks: followSymLinks, isFile: &isFile1, isFolder: &isFolder1)
        other.determineFileTypeWhen(followSymLinks: followSymLinks, isFile: &isFile2, isFolder: &isFolder2)

        // check if invalid files have path otherwise isn't necessary to compare
        let bothInvalidWithPath = !isValidFile && !other.isValidFile && (path != nil || other.path != nil)

        if (isFolder1 && isFolder2) || (isFile1 && isFile2) || bothInvalidWithPath {
            return comparator(self, other)
        }
        // Place directories before files
        return isFolder1 ? .orderedAscending : .orderedDescending
    }

    func compare(
        forAlign rhs: CompareItem,
        followSymLinks: Bool,
        insensitiveCompare: Bool
    ) -> ComparisonResult {
        compare(
            rhs,
            followSymLinks: followSymLinks
        ) {
            guard let lhsFileName = $0.fileName else {
                return .orderedAscending
            }
            guard let rhsFileName = $1.fileName else {
                return .orderedDescending
            }
            return insensitiveCompare
                ? lhsFileName.localizedCaseInsensitiveCompare(rhsFileName)
                : lhsFileName.localizedCompare(rhsFileName)
        }
    }

    func compare(
        forList other: CompareItem,
        followSymLinks: Bool
    ) -> ComparisonResult {
        compare(
            other,
            followSymLinks: followSymLinks
        ) {
            guard let lhsFileName = $0.fileName else {
                return .orderedAscending
            }
            guard let rhsFileName = $1.fileName else {
                return .orderedDescending
            }
            return lhsFileName.localizedCompare(rhsFileName)
        }
    }

    func evaluate(filter: NSPredicate) -> Bool {
        guard isValidFile else {
            return false
        }
        var dict = [String: Any]()

        dict["fileName"] = fileName
        dict["pathRelativeToRoot"] = pathRelativeToRoot

        // only the files use modification date and the size
        if isFile {
            dict["fileObjectModificationDate"] = fileModificationDate
            dict["fileSize"] = NSNumber(value: fileSize)
        }

        return filter.evaluate(with: dict)
    }
}
