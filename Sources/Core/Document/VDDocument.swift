//
//  VDDocument.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

import os.log

public protocol DocumentWindowControllerDelegate: AnyObject {
    func canClose(_ document: VDDocument) -> Bool
}

// the attribute @objc is necessary to work correctly in Swift
@objc(VDDocument)
public class VDDocument: NSPersistentDocument {
    private var windowController: NSWindowController?
    private var documentManagedObjectModel: NSManagedObjectModel?

    // Cocoa can call [self close] multiple times so we must check it manually
    // see http://lists.apple.com/archives/cocoa-dev/2012/Sep/msg00428.html
    private var isClosed = false

    let uuid = ProcessInfo.processInfo.globallyUniqueString

    var parentSession: DiffOpenerDelegate?

    // MARK: - sessionDiff field

    private var _sessionDiff: SessionDiff?

    var sessionDiff: SessionDiff? {
        get {
            if _sessionDiff != nil {
                return _sessionDiff
            }

            guard let moc = managedObjectContext else {
                fatalError("managedObjectContext is nil")
            }
            let fetchRequest = SessionDiff.fetchRequest()

            do {
                _sessionDiff = try moc.fetch(fetchRequest).first
            } catch {
                presentError(error)
            }

            return _sessionDiff
        }

        set {
            _sessionDiff = newValue
        }
    }

    // MARK: - init

    // —initWithType:error:—that is called only when a new document is created, not when it is subsequently reopened.
    @MainActor
    convenience init(type _: String) throws {
        self.init()

        guard let moc = managedObjectContext else {
            return
        }
        moc.rollback()

        moc.updateWithoutRecordingModifications {
            _sessionDiff = SessionDiff.newObject(moc)
            if let sessionDiff {
                VDDocumentController.shared.fillSessionDiff(sessionDiff)
            }
        }
    }

    override open nonisolated func read(from absoluteURL: URL, ofType typeName: String) throws {
        try super.read(from: absoluteURL, ofType: typeName)

        try MainActor.assumeIsolated {
            try isReadSessionDiffValid()
        }
    }

    override open func save(_ sender: Any?) {
        super.save(sender)

        // If user drags path ensure it is saved as secure bookmark
        guard let sessionDiff,
              let leftPath = sessionDiff.leftPath,
              let rightPath = sessionDiff.rightPath else {
            return
        }

        let leftUrl = URL(filePath: leftPath)
        let rightUrl = URL(filePath: rightPath)

        SecureBookmark.shared.add(leftUrl)
        SecureBookmark.shared.add(rightUrl)
    }

    func isReadSessionDiffValid() throws {
        guard let sessionDiff,
              let leftPath = sessionDiff.leftPath,
              let rightPath = sessionDiff.rightPath else {
            throw DocumentError.invalidSessionData
        }

        let leftUrl = URL(filePath: leftPath)
        let rightUrl = URL(filePath: rightPath)

        let leftSecureUrl = SecureBookmark.shared.secure(fromBookmark: leftUrl, startSecured: true)
        defer {
            SecureBookmark.shared.stopAccessing(url: leftSecureUrl)
        }

        let rightSecureURL = SecureBookmark.shared.secure(fromBookmark: rightUrl, startSecured: true)
        defer {
            SecureBookmark.shared.stopAccessing(url: rightSecureURL)
        }

        guard let itemType = sessionDiff.itemType else {
            throw DocumentError.unknownSessionType
        }
        try itemType.checkPaths(leftPath: leftPath, rightPath: rightPath)
    }

    override public func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        // Prepare a suggested file name only if the document is new (ie never saved before)
        if fileURL != nil {
            return super.prepareSavePanel(savePanel)
        }
        guard let sessionDiff,
              var leftName = fileName(sessionDiff.leftPath),
              var rightName = fileName(sessionDiff.rightPath),
              let defaultType = NSDocumentController.shared.defaultType,
              let ext = fileNameExtension(forType: defaultType, saveOperation: .saveOperation) else {
            return super.prepareSavePanel(savePanel)
        }

        if leftName.isEmpty {
            leftName = rightName
        }
        if rightName.isEmpty {
            rightName = leftName
        }
        savePanel.nameFieldStringValue = if leftName == rightName {
            String(format: "%@.%@", leftName, ext)
        } else {
            String(format: "%@ vs %@.%@", leftName, rightName, ext)
        }

        return true
    }

    func fileName(_ absolutePath: String?) -> String? {
        guard let absolutePath else {
            return nil
        }
        let dotSet = CharacterSet(charactersIn: ".")

        var url = URL(filePath: absolutePath)
        url.deletePathExtension()

        return url.lastPathComponent.trimmingCharacters(in: dotSet)
    }

    override public func makeWindowControllers() {
        guard let sessionDiff,
              sessionDiff.leftPath != nil,
              sessionDiff.rightPath != nil else {
            super.makeWindowControllers()
            return
        }
        switch sessionDiff.itemType {
        case .folder:
            let fwc = FoldersWindowController()
            windowController = fwc
            addWindowController(fwc)
            fwc.startComparison()
        case .file:
            let fwc = FilesWindowController()
            windowController = fwc
            addWindowController(fwc)
            fwc.startComparison()
        default:
            Logger.general.error("Invalid session type")
        }
        // disable restoration for new documents
        // otherwise when the application restarts it restores an invalid document
        if fileURL == nil {
            windowController?.window?.isRestorable = false
        }
    }

    override public func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        if let delegate = windowController as? DocumentWindowControllerDelegate,
           delegate.canClose(self) {
            close()
        }

        super.canClose(withDelegate: delegate, shouldClose: shouldCloseSelector, contextInfo: contextInfo)
    }

    override public func close() {
        if isClosed {
            super.close()
            return
        }
        isClosed = true

        // TODO: update only if document is edited but do not call self.isDocumentEdited because is overridden
        if super.isDocumentEdited {
            HistorySessionManager.shared.update(document: self, closeDocument: true)
        }
        DistributedNotificationCenter.default.post(
            name: .documentClosed,
            object: uuid
        )

        super.close()
    }

    override public nonisolated func write(
        to absoluteURL: URL,
        ofType typeName: String,
        for saveOperation: NSDocument.SaveOperationType,
        originalContentsURL absoluteOriginalContentsURL: URL?
    ) throws {
        try super.write(
            to: absoluteURL,
            ofType: typeName,
            for: saveOperation,
            originalContentsURL: absoluteOriginalContentsURL
        )

        // documents never saved (eg new documents) has restoration disabled but now
        // they can safety restored as application restart time
        MainActor.assumeIsolated {
            windowController?.window?.isRestorable = true
        }
    }

    override public var isDocumentEdited: Bool {
        // If pref is set to true then consider the document without modifications so the save dialog will never shown
        if CommonPrefs.shared.bool(forKey: .dontAskSave) {
            return false
        }
        return super.isDocumentEdited
    }

    override public var managedObjectModel: NSManagedObjectModel? {
        // By default the Core Data framework creates a merged model from all models in the application bundle
        // so we force it to use only the document model
        if documentManagedObjectModel == nil {
            if let modelURL = Bundle.main.url(forResource: "MyDocument", withExtension: "momd") {
                documentManagedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
            }
        }
        return documentManagedObjectModel
    }

    // displayName is declared as null_resettable so the unwrap is by design
    // swiftlint:disable:next implicitly_unwrapped_optional
    override public var displayName: String! {
        get {
            // Show title using the sessionDiff path instead of the resolved one
            guard let sessionDiff,
                  var leftPath = sessionDiff.leftPath,
                  let rightPath = sessionDiff.rightPath else {
                return super.displayName
            }
            if leftPath.isEmpty, rightPath.isEmpty {
                return super.displayName
            }
            let leftName = URL(filePath: leftPath).lastPathComponent
            let rightName = URL(filePath: rightPath).lastPathComponent

            if leftName != rightName {
                return String(
                    format: "%@ - %@ <=> %@",
                    super.displayName,
                    leftName,
                    rightName
                )
            }
            if leftPath.isEmpty {
                leftPath = rightPath
            }
            return String(
                format: "%@ - %@",
                super.displayName,
                leftName
            )
        }

        set {
            super.displayName = newValue
        }
    }

    override public func configurePersistentStoreCoordinator(
        for url: URL,
        ofType fileType: String,
        modelConfiguration configuration: String?,
        storeOptions: [String: Any]? = nil
    ) throws {
        // use lightweight migration
        var options = storeOptions ?? [:]
        options[NSMigratePersistentStoresAutomaticallyOption] = true
        options[NSInferMappingModelAutomaticallyOption] = true

        try super.configurePersistentStoreCoordinator(
            for: url,
            ofType: fileType,
            modelConfiguration: configuration,
            storeOptions: options
        )
    }
}

public extension Notification.Name {
    static let documentClosed = Notification.Name("VDDocumentClosedNotification")
}

public extension CommonPrefs.Name {
    static let dontAskSave = CommonPrefs.Name(rawValue: "dontAskToSaveSession")
}
