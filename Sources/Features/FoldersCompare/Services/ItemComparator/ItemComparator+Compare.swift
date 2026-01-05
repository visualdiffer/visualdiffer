//
//  ItemComparator+Compare.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension ItemComparator {
    /**
     * Determine the comparison to apply (timestamp, size, ...) based on the comparatorOptions value
     * This method must always be used to make comparisons
     */
    @discardableResult
    public func compare(_ lhs: CompareItem, _ rhs: CompareItem) -> ComparisonResult {
        var res: ComparisonResult = .orderedSame
        let canCompareFolders = !options.isDisjoint(with: .supportFolderCompare)

        if !canCompareFolders, !lhs.isFile || !rhs.isFile {
            return res
        }

        if lhs.isValidFile, rhs.isValidFile {
            // Run only the comparisons supported by folders
            if lhs.isFolder {
                // label and tags are mutually exclusive
                if options.contains(.finderLabel) {
                    res = compareFinderLabel(lhs, rhs)
                } else if options.contains(.finderTags) {
                    res = compareFinderTag(lhs, rhs)
                }
                return res
            }
            // label and tags are mutually exclusive
            if options.contains(.finderLabel) {
                res = compareFinderLabel(lhs, rhs)
            } else if options.contains(.finderTags) {
                res = compareFinderTag(lhs, rhs)
            }
            if res == .orderedSame, options.contains(.contentTimestamp) {
                res = compareContentAndTimestamp(lhs, rhs)
            } else {
                if res == .orderedSame, options.contains(.filename) {
                    res = compareFilename(lhs, rhs)
                }
                if res == .orderedSame, options.contains(.timestamp) {
                    res = compareTimestamp(lhs, rhs)
                }
                if res == .orderedSame, options.contains(.size) {
                    res = compareSize(lhs, rhs)
                }
                if res == .orderedSame, options.contains(.content) {
                    res = compareContent(lhs, rhs, ignoreLineEndingDiff: false)
                }
                if res == .orderedSame, options.contains(.asText) {
                    res = compareContent(lhs, rhs, ignoreLineEndingDiff: true)
                }
            }
        } else if lhs.isValidFile {
            lhs.addOrphanFiles(1)
            res = .orderedAscending
        } else if rhs.isValidFile {
            rhs.addOrphanFiles(1)
            res = .orderedDescending
        }
        return res
    }

    private func compareFinderLabel(_ lhs: CompareItem, _ rhs: CompareItem) -> ComparisonResult {
        guard let lhsPath = lhs.toUrl(),
              let rhsPath = rhs.toUrl(),
              let leftLabelNumber = lhsPath.labelNumber(),
              let rightLabelNumber = rhsPath.labelNumber() else {
            return .orderedSame
        }

        if leftLabelNumber == rightLabelNumber {
            return .orderedSame
        }

        lhs.addMismatchingLabels(1)
        rhs.addMismatchingLabels(1)

        if lhs.isFolder {
            lhs.setMismatchingFolderMetadataLabels(true)
            rhs.setMismatchingFolderMetadataLabels(true)
        }

        return leftLabelNumber < rightLabelNumber ? .orderedAscending : .orderedDescending
    }

    private func compareFinderTag(_ lhs: CompareItem, _ rhs: CompareItem) -> ComparisonResult {
        guard let lhsPath = lhs.toUrl(),
              let rhsPath = rhs.toUrl(),
              let leftTags = lhsPath.tagNames(sorted: true),
              let rightTags = rhsPath.tagNames(sorted: true) else {
            return .orderedSame
        }

        var res: ComparisonResult = leftTags.count == rightTags.count
            ? .orderedSame
            : leftTags.count < rightTags.count ? .orderedAscending : .orderedDescending
        if res == .orderedSame {
            for (index, item) in leftTags.enumerated() where res == .orderedSame {
                res = item.caseInsensitiveCompare(rightTags[index])
            }
        }

        if res != .orderedSame {
            if lhs.isFile {
                lhs.addMismatchingTags(1)
                rhs.addMismatchingTags(1)
            } else {
                lhs.setMismatchingFolderMetadataTags(true)
                rhs.setMismatchingFolderMetadataTags(true)
            }
        }
        return res
    }

    private func compareContentAndTimestamp(_ lhs: CompareItem, _ rhs: CompareItem) -> ComparisonResult {
        var sign = compareSize(lhs, rhs)

        if sign == .orderedSame {
            sign = compareContent(lhs, rhs, ignoreLineEndingDiff: false)
        }

        if sign != .orderedSame {
            // return the content sign
            if compareTimestamp(lhs, rhs) == .orderedSame {
                lhs.addChangedFiles(1)
                rhs.addChangedFiles(1)
            }
        }
        return sign
    }

    private func compareSize(_ lhs: CompareItem, _ rhs: CompareItem) -> ComparisonResult {
        let sign = lhs.fileSize - rhs.fileSize

        if sign < 0 {
            lhs.addChangedFiles(1)
            rhs.addChangedFiles(1)
            return .orderedAscending
        }
        if sign > 0 {
            lhs.addChangedFiles(1)
            rhs.addChangedFiles(1)
            return .orderedDescending
        }
        lhs.addMatchedFiles(1)
        rhs.addMatchedFiles(1)

        return .orderedSame
    }

    public func compareContent(
        _ lhs: CompareItem,
        _ rhs: CompareItem,
        ignoreLineEndingDiff: Bool
    ) -> ComparisonResult {
        if ignoreLineEndingDiff {
            return compareAsText(lhs, rhs)
        } else {
            if lhs.fileSize != rhs.fileSize {
                lhs.addChangedFiles(1)
                rhs.addChangedFiles(1)
                return lhs.fileSize < rhs.fileSize ? .orderedAscending : .orderedDescending
            }
        }
        guard let lhsPath = lhs.toUrl(),
              let rhsPath = rhs.toUrl() else {
            return .orderedSame
        }

        var ret: ComparisonResult = .orderedSame

        do {
            ret = try compareBinaryFiles(lhsPath, rhsPath, bufferSize) {
                delegate?.isRunning(self) ?? false
            }
        } catch {}

        // check resource data
        if ret == .orderedSame, lhs.isResourceFork, rhs.isResourceFork {
            if let leftData = try? lhsPath.readResFork(),
               let rightData = try? rhsPath.readResFork(),
               !leftData.elementsEqual(rightData) {
                ret = .orderedAscending
            }
        }

        if ret == .orderedSame {
            lhs.addMatchedFiles(1)
            rhs.addMatchedFiles(1)
        } else {
            lhs.addChangedFiles(1)
            rhs.addChangedFiles(1)
        }

        return ret
    }

    private func compareTimestamp(_ lhs: CompareItem, _ rhs: CompareItem) -> ComparisonResult {
        guard let lhsDate = lhs.fileModificationDate,
              let rhsDate = rhs.fileModificationDate else {
            return .orderedSame
        }

        let result = compareDates(lhsDate, rhsDate, timestampToleranceSeconds)

        switch result {
        case .orderedAscending:
            lhs.addOlderFiles(1)
            rhs.addChangedFiles(1)
        case .orderedDescending:
            lhs.addChangedFiles(1)
            rhs.addOlderFiles(1)
        default:
            lhs.addMatchedFiles(1)
            rhs.addMatchedFiles(1)
        }

        return result
    }

    private func compareAsText(_ lhs: CompareItem, _ rhs: CompareItem) -> ComparisonResult {
        guard let lhsPath = lhs.toUrl(),
              let rhsPath = rhs.toUrl() else {
            return .orderedSame
        }

        do {
            let ret = try compareTextFiles(
                lhsPath,
                rhsPath,
                .utf8,
                bufferSize
            ) {
                delegate?.isRunning(self) ?? false
            }
            if ret == .orderedSame {
                lhs.addMatchedFiles(1)
                rhs.addMatchedFiles(1)
            } else {
                lhs.addChangedFiles(1)
                rhs.addChangedFiles(1)
            }
            return ret
        } catch {
            return .orderedSame
        }
    }

    private func compareFilename(_ lhs: CompareItem, _ rhs: CompareItem) -> ComparisonResult {
        // no comparison is necessary so simply mark files as matched
        lhs.addMatchedFiles(1)
        rhs.addMatchedFiles(1)

        return .orderedSame
    }
}
