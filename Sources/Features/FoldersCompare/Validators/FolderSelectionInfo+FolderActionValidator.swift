//
//  FolderSelectionInfo+FolderActionValidator.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/03/21.
//  Copyright (c) 2021 visualdiffer.com
//

@MainActor extension FolderSelectionInfo {
    func validateSetAsBaseFolder() -> Bool {
        foldersCount == 1
    }

    func validateSetAsBaseFolderOtherSide() -> Bool {
        foldersCount == 1
    }

    func validateSetAsBaseFoldersBothSides() -> Bool {
        guard let linkedSelInfo = view.linkedView?.selectionInfo else {
            return false
        }

        if selType == .folder, linkedSelInfo.selType.isEmpty {
            return foldersCount == 2
        }
        if selType == .folder, linkedSelInfo.selType == .folder {
            return foldersCount == 1 && linkedSelInfo.foldersCount == 1
        }
        return false
    }

    func validateExpandSelectedSubfolders() -> Bool {
        filesCount == 0 && foldersCount > 0
    }
}
