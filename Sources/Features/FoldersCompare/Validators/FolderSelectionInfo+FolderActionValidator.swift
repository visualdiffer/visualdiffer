//
//  FolderSelectionInfo+FolderActionValidator.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/03/21.
//  Copyright (c) 2021 visualdiffer.com
//

@MainActor
extension FolderSelectionInfo {
    func validateSetAsBaseFolder() -> Bool {
        foldersCount == 1
    }

    func validateSetAsBaseFolderOtherSide() -> Bool {
        foldersCount == 1
    }

    func validateSetAsBaseFoldersBothSides() -> Bool {
        hasFolderPair
    }

    func validateExpandSelectedSubfolders() -> Bool {
        !hasFiles && hasFolders
    }
}
