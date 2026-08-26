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

    var compareItemsTitle: String {
        switch (comparableType, hasPairOnSingleSide, view.side) {
        case (.file?, false, _):
            NSLocalizedString("Compare Files", comment: "")
        case (.file?, true, .left):
            NSLocalizedString("Compare Files on Left", comment: "")
        case (.file?, true, .right):
            NSLocalizedString("Compare Files on Right", comment: "")
        case (.folder?, false, _):
            NSLocalizedString("Compare Folders", comment: "")
        case (.folder?, true, .left):
            NSLocalizedString("Compare Folders on Left", comment: "")
        case (.folder?, true, .right):
            NSLocalizedString("Compare Folders on Right", comment: "")
        case (_, _, .left):
            NSLocalizedString("Compare on Left", comment: "")
        case (_, _, .right):
            NSLocalizedString("Compare on Right", comment: "")
        }
    }
}
