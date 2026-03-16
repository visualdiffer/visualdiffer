//
//  VDDocumentController+BlankDocument.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/03/26.
//  Copyright (c) 2026 visualdiffer.com
//

extension VDDocumentController {
    @discardableResult
    func openBlankDocument(_ itemType: SessionDiff.ItemType) throws -> VDDocument? {
        try openDocumentWithBlock { document in
            if let sessionDiff = document.sessionDiff {
                sessionDiff.itemType = itemType
                sessionDiff.leftPath = ""
                sessionDiff.leftReadOnly = false
                sessionDiff.rightPath = ""
                sessionDiff.rightReadOnly = false
                sessionDiff.expandAllFolders = CommonPrefs.shared.bool(forKey: .expandAllFolders)
            }
        }
    }

    @IBAction func openBlankFileCompare(_: AnyObject?) {
        do {
            try openBlankDocument(.file)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    @IBAction func openBlankFolderCompare(_: AnyObject?) {
        do {
            try openBlankDocument(.folder)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
