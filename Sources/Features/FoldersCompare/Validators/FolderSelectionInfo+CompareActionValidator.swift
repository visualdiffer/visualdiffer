//
//  FolderSelectionInfo+CompareActionValidator.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/03/21.
//  Copyright (c) 2021 visualdiffer.com
//

@MainActor
extension FolderSelectionInfo {
    func validateCompareFiles() -> Bool {
        guard let linkedSelInfo = view.linkedView?.selectionInfo else {
            return false
        }
        if selType == .file, linkedSelInfo.selType.isEmpty {
            return filesCount == 2
        }
        if selType == .file, linkedSelInfo.selType == .file {
            return filesCount == 1 && linkedSelInfo.filesCount == 1
        }
        return false
    }

    func validateCompareFolders() -> Bool {
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
}
