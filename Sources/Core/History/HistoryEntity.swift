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

        Self.copySessionDiff(source: sessionDiff, destination: self)
    }

    func fill(sessionDiff: SessionDiff) {
        Self.copySessionDiff(source: self, destination: sessionDiff)
    }

    private static func copySessionDiff(source: SessionDiff, destination: SessionDiff) {
        destination.leftPath = source.leftPath
        destination.leftReadOnly = source.leftReadOnly

        destination.rightPath = source.rightPath
        destination.rightReadOnly = source.rightReadOnly

        destination.expandAllFolders = source.expandAllFolders

        destination.itemType = source.itemType

        destination.comparatorOptions = source.comparatorOptions
        destination.displayOptions = source.displayOptions
        destination.followSymLinks = source.followSymLinks
        destination.timestampToleranceSeconds = source.timestampToleranceSeconds
        destination.exclusionFileFilters = source.exclusionFileFilters
        destination.skipPackages = source.skipPackages
        destination.fileExtraOptions = source.fileExtraOptions
        destination.traverseFilteredFolders = source.traverseFilteredFolders
        destination.fileNameAlignments = source.fileNameAlignments

        destination.currentSortColumn = source.currentSortColumn
        destination.isCurrentSortAscending = source.isCurrentSortAscending
        destination.currentSortSide = source.currentSortSide

        destination.extraData = source.extraData
    }
}
