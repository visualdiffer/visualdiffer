//
//  VDDocumentController.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/08/11.
//  Copyright (c) 2011 visualdiffer.com
//

import os.log

enum MainMenu: Int {
    case application
    case file
    case edit
    case navigate
    case actions
    case view
    case window
    case help
}

class VDDocumentController: NSDocumentController {
    private let documentWindow: DocumentWindow

    override class var shared: VDDocumentController {
        // swiftlint:disable:next force_cast
        NSDocumentController.shared as! VDDocumentController
    }

    override init() {
        documentWindow = DocumentWindow()

        super.init()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func removeDocument(_ document: NSDocument) {
        super.removeDocument(document)

        if documents.isEmpty {
            newDocument(nil)
        }
    }

    // MARK: - Actions

    override func newDocument(_ sender: Any?) {
        // documentWindow can call NSDocumentController.newDocument so if it's the caller we redirect to `super`
        if let sender = sender as? DocumentWindow, sender === documentWindow {
            super.newDocument(sender)
        } else {
            documentWindow.newDocument(self)
        }
    }

    override func openDocument(_ sender: Any?) {
        documentWindow.orderOut(self)
        super.openDocument(sender)
    }

    override func addDocument(_ document: NSDocument) {
        documentWindow.orderOut(self)
        super.addDocument(document)
    }

    override func openUntitledDocumentAndDisplay(_ displayDocument: Bool) throws -> NSDocument {
        // This method is called from newDocument originally called from showDiff
        let doc = try super.openUntitledDocumentAndDisplay(displayDocument)

        if let doc = doc as? VDDocument {
            HistorySessionManager.shared.add(document: doc)
        }
        return doc
    }

    // MARK: - SessionDiff related methods

    @discardableResult
    func fillSessionDiff(_ sessionDiff: SessionDiff) -> Bool {
        documentWindow.fillSessionDiff(sessionDiff)
    }

    @discardableResult
    func openDifferDocument(leftUrl: URL?, rightUrl: URL?) throws -> VDDocument? {
        // at least one path must be set
        if leftUrl == nil && rightUrl == nil {
            return nil
        }

        let hasMissingPath = leftUrl == nil || rightUrl == nil
        var isFolder = false
        var leftPathExists = false
        var rightPathExists = false

        let canOpenDocument = if hasMissingPath {
            true
        } else if let leftUrl, let rightUrl, leftUrl.matchesFileType(
            of: rightUrl,
            isDir: &isFolder,
            leftExists: &leftPathExists,
            rightExists: &rightPathExists
        ) {
            true
        } else {
            false
        }

        guard canOpenDocument else {
            if !leftPathExists, let leftUrl {
                throw SessionTypeError.invalidItem(path: leftUrl.osPath, isFolder: isFolder)
            }
            if !rightPathExists, let rightUrl {
                throw SessionTypeError.invalidItem(path: rightUrl.osPath, isFolder: isFolder)
            }
            throw SessionTypeError.unknownError
        }
        // when comparing folders both paths must be set
        if isFolder, hasMissingPath {
            throw SessionTypeError.invalidAllItems(isFolder: true)
        }
        return try openDocumentWithBlock { document in
            if let sessionDiff = document.sessionDiff {
                sessionDiff.itemType = isFolder ? .folder : .file
                sessionDiff.leftPath = leftUrl?.standardizingPath ?? ""
                sessionDiff.leftReadOnly = false
                sessionDiff.rightPath = rightUrl?.standardizingPath ?? ""
                sessionDiff.rightReadOnly = false
                sessionDiff.expandAllFolders = CommonPrefs.shared.bool(forKey: .expandAllFolders)
            }
        }
    }

    /**
     * Open document and allows to update the sessionDiff without mark it as edited
     */
    @discardableResult
    func openDocumentWithBlock(_ block: (VDDocument) -> Void) throws -> VDDocument? {
        let docController = NSDocumentController.shared
        guard let defaultType = docController.defaultType,
              let doc = try? docController.makeUntitledDocument(ofType: defaultType) as? VDDocument,
              let moc = doc.managedObjectContext else {
            return nil
        }

        moc.rollback()
        moc.updateWithoutRecordingModifications {
            doc.sessionDiff = SessionDiff.newObject(moc)
            block(doc)
        }

        docController.addDocument(doc)
        doc.makeWindowControllers()
        doc.showWindows()

        return doc
    }

    // MARK: - Migration support methods

    override func makeDocument(withContentsOf url: URL, ofType typeName: String) throws -> NSDocument {
        // I'm pretty sure this code doesn't work :(
        let migrationController = TOPMigrationController(modelName: "MyDocument")

        guard (try? migrationController.requiresMigration(url)) != nil,
              let destinationURL = TOPMigrationController.pickDestinationURL(with: url) else {
            return try super.makeDocument(withContentsOf: url, ofType: typeName)
        }

        do {
            try migrationController.migrateURL(url, to: destinationURL)
            return try super.makeDocument(withContentsOf: destinationURL, ofType: typeName)
        } catch {
            Logger.general.error("Error while migrating \(url) to \(destinationURL) \(error)")
        }
        return try super.makeDocument(withContentsOf: url, ofType: typeName)
    }
}
