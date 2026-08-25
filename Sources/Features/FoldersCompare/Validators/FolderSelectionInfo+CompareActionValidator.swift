//
//  FolderSelectionInfo+CompareActionValidator.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/03/21.
//  Copyright (c) 2021 visualdiffer.com
//

@MainActor
extension FolderSelectionInfo {
    var comparableType: SelectionType? {
        if hasFilePair {
            return .file
        }
        if hasFolderPair {
            return .folder
        }
        return nil
    }
}
