//
//  FolderSelectionInfo+FileSystemActionValidator.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/03/21.
//  Copyright (c) 2021 visualdiffer.com
//

@MainActor extension FolderSelectionInfo {
    func validateCopyFiles(_ sessionDiff: SessionDiff) -> Bool {
        let isValid = switch view.side {
        case .left:
            !sessionDiff.rightReadOnly
        case .right:
            !sessionDiff.leftReadOnly
        }
        return isValid && (foldersCount > 0 || filesCount > 0)
    }

    func validateMoveFiles(_ sessionDiff: SessionDiff) -> Bool {
        let isValid = switch view.side {
        case .left:
            !sessionDiff.leftReadOnly && !sessionDiff.rightReadOnly
        case .right:
            !sessionDiff.leftReadOnly && !sessionDiff.rightReadOnly
        }
        return isValid && (foldersCount > 0 || filesCount > 0)
    }

    func validateSyncFiles(_ sessionDiff: SessionDiff) -> Bool {
        let isValid = switch view.side {
        case .left:
            !sessionDiff.rightReadOnly
        case .right:
            !sessionDiff.leftReadOnly
        }
        return isValid && (foldersCount > 0 || filesCount > 0)
    }

    func validateDeleteFiles(_ sessionDiff: SessionDiff) -> Bool {
        let isValid = switch view.side {
        case .left:
            !sessionDiff.leftReadOnly
        case .right:
            !sessionDiff.rightReadOnly
        }
        return isValid && (foldersCount > 0 || filesCount > 0)
    }

    func validateFileTouch(_ sessionDiff: SessionDiff) -> Bool {
        let isValid = switch view.side {
        case .left:
            !sessionDiff.leftReadOnly
        case .right:
            !sessionDiff.rightReadOnly
        }
        return isValid && (foldersCount > 0 || filesCount > 0)
    }

    func validateClipboardCopy() -> Bool {
        !selType.isDisjoint(with: [.folder, .file]) || hasValidPaths
    }
}
