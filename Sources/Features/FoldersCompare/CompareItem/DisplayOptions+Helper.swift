//
//  DisplayOptions+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

public extension DisplayOptions {
    init(number: NSNumber?) {
        self.init(rawValue: number?.intValue ?? 0)
    }

    func toNumber() -> NSNumber {
        NSNumber(value: rawValue)
    }
}

public extension DisplayOptions {
    var onlyMethodFlags: Self {
        intersection(.fileTypeMask)
    }

    var withoutMethodFlags: Self {
        subtracting(.fileTypeMask)
    }

    func changeWithoutMethod(_ flags: Self) -> Self {
        withoutMethodFlags.union(flags)
    }

    func changeWithoutMethod(_ flags: Int) -> Self {
        withoutMethodFlags.union(.init(rawValue: flags))
    }
}

public extension DisplayOptions {
    /**
     * Determine if left and right can be displayed based on displayFilters
     * @param leftItem CompareItem
     * @param rightItem CompareItem
     * @param displayFilters the display filter value
     * @returns true if displayable, false otherwise
     */
    func isDisplayable(
        _ leftItem: CompareItem,
        rightItem: CompareItem
    ) -> Bool {
        if contains(.showAll) {
            return true
        }
        if contains(.onlyMismatches) {
            if leftItem.isFile {
                return leftItem.summary.containsDifferences() || rightItem.summary.containsDifferences()
            } else if contains(.dontFollowSymlinks) {
                return leftItem.isValidFile != rightItem.isValidFile
            } else if leftItem.isFolder {
                return leftItem.summary.hasMetadataTags || leftItem.summary.hasMetadataLabels
                    || rightItem.summary.hasMetadataTags || rightItem.summary.hasMetadataLabels
            }
            return leftItem.type == .orphan
        }
        if contains(.noOrphan) {
            if leftItem.isFile {
                return (leftItem.olderFiles > 0 || leftItem.changedFiles > 0 || leftItem.matchedFiles > 0)
                    && (rightItem.olderFiles > 0 || rightItem.changedFiles > 0 || rightItem.matchedFiles > 0)
            } else if contains(.dontFollowSymlinks) {
                return leftItem.isValidFile && rightItem.isValidFile
            }
            return leftItem.type == .orphan
        }
        if contains(.onlyOrphans) {
            if leftItem.isFile {
                return leftItem.orphanFiles > 0 || rightItem.orphanFiles > 0
            } else if contains(.dontFollowSymlinks) {
                return leftItem.isValidFile != rightItem.isValidFile
            }
            return leftItem.type == .orphan
        }
        if contains(.onlyMatches) {
            if contains(.dontFollowSymlinks) {
                return leftItem.isValidFile == rightItem.isValidFile
            }
            // no need to check also the right side
            // because it has the same informations
            return leftItem.matchedFiles > 0
        }
        return true
    }
}
