//
//  FolderSelectionInfo+FilterActionValidator.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/03/21.
//  Copyright (c) 2021 visualdiffer.com
//

@MainActor
extension FolderSelectionInfo {
    func validateExclude(byName outExcludedFileName: inout String?) -> Bool {
        if selType.isEmpty || selType == .nullfile {
            return false
        }
        if outExcludedFileName != nil {
            // Only one element selected
            if filesCount + foldersCount == 1 {
                if let row = filesCount > 0 ? filesIndexes.first : foldersIndexes.first,
                   let vi = view.item(atRow: row) as? VisibleItem {
                    let item = vi.item
                    outExcludedFileName = foldersCount == 1 ? item.pathRelativeToRoot : item.fileName
                }
            } else {
                outExcludedFileName = nil
            }
        }

        return true
    }

    func validateExclude(byExt outExcludedExt: inout String?) -> Bool {
        // Only valid for selection containing only files (null files are skipped)
        if filesCount == 0 || foldersCount > 0 {
            return false
        }
        let indexes = filesIndexes

        guard let row = indexes.first,
              let vi = view.item(atRow: row) as? VisibleItem else {
            return false
        }
        let item = vi.item

        guard let path = item.toUrl() else {
            return false
        }

        var allFilesWithSameExt = true
        let fileExt = path.pathExtension

        for row in indexes.dropFirst() where allFilesWithSameExt {
            if let viAtRow = view.item(atRow: row) as? VisibleItem {
                let itemAtRow = viAtRow.item
                if let path = itemAtRow.toUrl() {
                    let tempExt = path.pathExtension
                    allFilesWithSameExt = tempExt == fileExt
                }
            }
        }

        if outExcludedExt != nil {
            outExcludedExt = fileExt
        }
        return allFilesWithSameExt
    }
}
