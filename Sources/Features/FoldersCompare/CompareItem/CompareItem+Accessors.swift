//
//  CompareItem+Accessors.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension CompareItem {
    // MARK: - FileFlags Accessors

    var isValidFile: Bool {
        fileFlags[.isValidFile]
    }

    var isSymbolicLink: Bool {
        fileFlags[.isSymbolicLink]
    }

    var isFile: Bool {
        fileFlags[.isFile]
    }

    var isFolder: Bool {
        fileFlags[.isFolder]
    }

    var isPackage: Bool {
        fileFlags[.isPackage]
    }

    var isOrphanFile: Bool {
        isValidFile && isFile && orphanFiles > 0
    }

    var isResourceFork: Bool {
        fileFlags[.isResourceFork]
    }

    var isLocked: Bool {
        fileFlags[.isLocked]
    }

    var isOrphanFolder: Bool {
        guard let linkedItem else {
            return false
        }

        return isFolder && !linkedItem.isValidFile
    }

    var isNewerThanLinked: Bool {
        guard let linkedItem else {
            return false
        }

        return type == .changed && linkedItem.type == .old
    }

    // MARK: - Counter Accessors

    var olderFiles: Int {
        summary.olderFiles
    }

    var changedFiles: Int {
        summary.changedFiles
    }

    var orphanFiles: Int {
        summary.orphanFiles
    }

    var matchedFiles: Int {
        summary.matchedFiles
    }

    var subfoldersSize: Int64 {
        summary.subfoldersSize
    }

    var mismatchingTags: Int {
        summary.mismatchingTags
    }

    var mismatchingLabels: Int {
        summary.mismatchingLabels
    }

    var mismatchingFolderMetadata: MismatchingFolderMetadata {
        summary.mismatchingFolderMetadata
    }
}
