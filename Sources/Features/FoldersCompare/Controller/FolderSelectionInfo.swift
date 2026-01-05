//
//  FolderSelectionInfo.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

struct SelectionType: OptionSet {
    let rawValue: Int

    static let nullfile = SelectionType(rawValue: 1 << 0)
    static let folder = SelectionType(rawValue: 1 << 1)
    static let file = SelectionType(rawValue: 1 << 2)
}

@MainActor struct FolderSelectionInfo: @preconcurrency CustomDebugStringConvertible {
    private(set) var selType: SelectionType = []
    private(set) var nullFilesCount = 0
    private(set) var foldersCount = 0
    private(set) var filesCount = 0
    private(set) var hasValidPaths = false
    private(set) var hasMultipleSel = false

    let view: FoldersOutlineView
    private(set) var foldersIndexes: IndexSet
    private(set) var filesIndexes: IndexSet

    // contains all valid folders and files indexes
    private(set) var validObjectsIndexes: [Int]

    init(view: FoldersOutlineView) {
        self.view = view
        let indexes = view.selectedRowIndexes
        var folders = IndexSet()
        var files = IndexSet()
        hasMultipleSel = !indexes.isEmpty

        validObjectsIndexes = []

        // Determine if all selected items aren't files
        for row in indexes {
            guard let item = (view.item(atRow: row) as? VisibleItem)?.item else {
                continue
            }

            if !item.isValidFile {
                nullFilesCount += 1
            } else if item.isFolder {
                foldersCount += 1
                folders.insert(row)
                validObjectsIndexes.append(row)
            } else if item.isFile {
                filesCount += 1
                files.insert(row)
                validObjectsIndexes.append(row)
            }
            if item.path != nil {
                hasValidPaths = true
            }
        }
        if nullFilesCount > 0 {
            selType.insert(.nullfile)
        }
        if foldersCount > 0 {
            selType.insert(.folder)
        }
        if filesCount > 0 {
            selType.insert(.file)
        }
        foldersIndexes = folders
        filesIndexes = files
    }

    var debugDescription: String {
        String(
            format: "selType %ld, nullFilesCount %d, foldersCount %d, folders %@, filesCount %d, files %@, hasMultipleSel %d",
            selType.rawValue,
            nullFilesCount,
            foldersCount,
            foldersIndexes.description,
            filesCount,
            filesIndexes.description,
            hasMultipleSel
        )
    }
}
