//
//  FilesWindowController+Document.swift
//  VisualDiffer
//
//  Created by davide ficano on 04/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController: @preconcurrency DocumentWindowControllerDelegate {
    override open var document: AnyObject? {
        didSet {
            // create a shortcut to sessionDiff held by document
            if let sessionDiff = (document as? VDDocument)?.sessionDiff {
                self.sessionDiff = sessionDiff
                preferences.from(sessionDiff: sessionDiff)
                setupUIState()
            }
        }
    }

    // MARK: - DocumentWindowControllerDelegate methods

    // this message is sent by NSDocument::canCloseDocumentWithDelegate
    public func canClose(_ document: VDDocument) -> Bool {
        var closeDoc = false

        if leftView.isDirty || rightView.isDirty {
            closeDoc = alertSaveDirtyFiles()

            if closeDoc {
                let tmpLeftDirty = leftView.isDirty
                let tmpRightDirty = rightView.isDirty

                leftView.isDirty = false
                rightView.isDirty = false
                if document.isDocumentEdited {
                    leftView.isDirty = tmpLeftDirty
                    rightView.isDirty = tmpRightDirty
                    closeDoc = false
                }
            }
        }
        return closeDoc
    }
}
