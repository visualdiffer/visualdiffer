//
//  FolderSelectionInfo+ViewerActionValidator.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/03/21.
//  Copyright (c) 2021 visualdiffer.com
//

@MainActor
extension FolderSelectionInfo {
    func validateShowInFinder() -> Bool {
        !selType.isDisjoint(with: [.folder, .file])
    }

    func validateOpen(withApp outSelectedPath: inout String?) -> Bool {
        guard let itemRow = view.item(atRow: view.selectedRow) as? VisibleItem else {
            return false
        }
        let item = itemRow.item

        if let path = item.path, outSelectedPath != nil {
            outSelectedPath = path
        }

        return item.isValidFile
    }

    func validatePreviewPanel() -> Bool {
        foldersCount > 0 || filesCount > 0
    }
}
