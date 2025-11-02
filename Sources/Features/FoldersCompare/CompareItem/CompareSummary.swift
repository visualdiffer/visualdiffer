//
//  CompareSummary.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/24.
//  Copyright (c) 2024 visualdiffer.com
//

struct MismatchingFolderMetadata: OptionSet {
    let rawValue: Int

    static let tags = MismatchingFolderMetadata(rawValue: 1 << 0)
    static let labels = MismatchingFolderMetadata(rawValue: 1 << 1)
}

public struct CompareSummary: Sendable {
    var olderFiles: Int = 0
    var changedFiles: Int = 0
    var orphanFiles: Int = 0
    var matchedFiles: Int = 0
    var folders: Int = 0
    var subfoldersSize: Int64 = 0
    var mismatchingTags: Int = 0
    var mismatchingLabels: Int = 0
    // The info is relative only for folders = 0
    var mismatchingFolderMetadata: MismatchingFolderMetadata = []
}

public extension CompareSummary {
    static func += (lhs: inout CompareSummary, rhs: CompareSummary) {
        lhs.olderFiles += rhs.olderFiles
        lhs.changedFiles += rhs.changedFiles
        lhs.orphanFiles += rhs.orphanFiles
        lhs.subfoldersSize += rhs.subfoldersSize
        lhs.matchedFiles += rhs.matchedFiles
        lhs.folders += rhs.folders
        lhs.mismatchingTags += rhs.mismatchingTags
        lhs.mismatchingLabels += rhs.mismatchingLabels

        if rhs.mismatchingFolderMetadata.contains(.tags) {
            lhs.mismatchingTags += 1
        }

        if rhs.mismatchingFolderMetadata.contains(.labels) {
            lhs.mismatchingLabels += 1
        }
    }

    static func -= (lhs: inout CompareSummary, rhs: CompareSummary) {
        lhs.olderFiles -= rhs.olderFiles
        lhs.changedFiles -= rhs.changedFiles
        lhs.orphanFiles -= rhs.orphanFiles
        lhs.subfoldersSize -= rhs.subfoldersSize
        lhs.matchedFiles -= rhs.matchedFiles
        lhs.folders -= rhs.folders
        lhs.mismatchingTags -= rhs.mismatchingTags
        lhs.mismatchingLabels -= rhs.mismatchingLabels

        if rhs.mismatchingFolderMetadata.contains(.tags) {
            lhs.mismatchingTags -= 1
        }

        if rhs.mismatchingFolderMetadata.contains(.labels) {
            lhs.mismatchingLabels -= 1
        }
    }
}

public extension CompareSummary {
    @inline(__always) var hasMetadataTags: Bool {
        mismatchingFolderMetadata.contains(.tags)
    }

    @inline(__always) var hasMetadataLabels: Bool {
        mismatchingFolderMetadata.contains(.labels)
    }

    @inline(__always) func containsDifferences() -> Bool {
        olderFiles > 0
            || changedFiles > 0
            || orphanFiles > 0
            || mismatchingTags > 0
            || mismatchingLabels > 0
            || hasMetadataTags
            || hasMetadataLabels
    }

    @inline(__always) func containsOnlyMatches() -> Bool {
        olderFiles == 0
            && changedFiles == 0
            && orphanFiles == 0
            && mismatchingTags == 0
            && mismatchingLabels == 0
            && !hasMetadataTags
            && !hasMetadataLabels
            && matchedFiles > 0
    }
}

extension CompareSummary: CustomStringConvertible {
    public var description: String {
        String(
            format: "old = %ld, chg = %ld, add = %ld, subs = %lld, mch = %ld, fol %ld, tag = %ld, lbl = %ld ft = %ld",
            olderFiles,
            changedFiles,
            orphanFiles,
            subfoldersSize,
            matchedFiles,
            folders,
            mismatchingTags,
            mismatchingLabels,
            mismatchingFolderMetadata.rawValue
        )
    }
}
