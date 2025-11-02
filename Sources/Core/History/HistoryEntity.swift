//
//  HistoryEntity.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/01/16.
//  Copyright (c) 2016 visualdiffer.com
//

// keep the same entity name that Core Data expects from the model file
// the attribute @objc is necessary to work correctly in Swift
@objc(HistoryEntity) class HistoryEntity: SessionDiff {
    static let name = "HistoryEntity"

    @NSManaged var starred: NSNumber
    @NSManaged var updateTime: Date

    static func requestUpdateTime() -> NSFetchRequest<HistoryEntity> {
        let request = NSFetchRequest<HistoryEntity>(entityName: Self.name)
        request.sortDescriptors = [
            NSSortDescriptor(key: "updateTime", ascending: false),
        ]

        return request
    }

    static func searchPathRequest(
        leftPath: String,
        rightPath: String
    ) -> NSFetchRequest<HistoryEntity> {
        let request = NSFetchRequest<HistoryEntity>(entityName: HistoryEntity.name)
        request.predicate = NSPredicate(
            format: "leftPath == %@ and rightPath = %@",
            URL(filePath: leftPath).standardizingPath,
            URL(filePath: rightPath).standardizingPath
        )

        return request
    }

    func fill(with sessionDiff: SessionDiff) {
        updateTime = Date()
        starred = false

        leftPath = sessionDiff.leftPath
        leftReadOnly = sessionDiff.leftReadOnly

        rightPath = sessionDiff.rightPath
        rightReadOnly = sessionDiff.rightReadOnly

        expandAllFolders = sessionDiff.expandAllFolders

        itemType = sessionDiff.itemType

        comparatorOptions = sessionDiff.comparatorOptions
        displayOptions = sessionDiff.displayOptions
        followSymLinks = sessionDiff.followSymLinks
        timestampToleranceSeconds = sessionDiff.timestampToleranceSeconds
        exclusionFileFilters = sessionDiff.exclusionFileFilters
        skipPackages = sessionDiff.skipPackages
        fileExtraOptions = sessionDiff.fileExtraOptions
        traverseFilteredFolders = sessionDiff.traverseFilteredFolders
        fileNameAlignments = sessionDiff.fileNameAlignments

        currentSortColumn = sessionDiff.currentSortColumn
        isCurrentSortAscending = sessionDiff.isCurrentSortAscending
        currentSortSide = sessionDiff.currentSortSide
    }

    func fill(sessionDiff: SessionDiff) {
        sessionDiff.leftPath = leftPath
        sessionDiff.leftReadOnly = leftReadOnly

        sessionDiff.rightPath = rightPath
        sessionDiff.rightReadOnly = rightReadOnly

        sessionDiff.expandAllFolders = expandAllFolders

        sessionDiff.itemType = itemType

        sessionDiff.comparatorOptions = comparatorOptions
        sessionDiff.displayOptions = displayOptions
        sessionDiff.followSymLinks = followSymLinks
        sessionDiff.timestampToleranceSeconds = timestampToleranceSeconds
        sessionDiff.exclusionFileFilters = exclusionFileFilters
        sessionDiff.skipPackages = skipPackages
        sessionDiff.fileExtraOptions = fileExtraOptions
        sessionDiff.traverseFilteredFolders = traverseFilteredFolders
        sessionDiff.fileNameAlignments = fileNameAlignments

        sessionDiff.currentSortColumn = currentSortColumn
        sessionDiff.isCurrentSortAscending = isCurrentSortAscending
        sessionDiff.currentSortSide = currentSortSide
    }
}
