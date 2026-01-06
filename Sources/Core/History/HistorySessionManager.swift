//
//  HistorySessionManager.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/04/15.
//  Copyright (c) 2015 visualdiffer.com
//

import os.log

class HistorySessionManager: @unchecked Sendable {
    static let defaultMaxItemsCount = 50

    static let historyFileName = "historySessions.sqlite"

    static let shared = HistorySessionManager()

    private(set) var historyMOC: NSManagedObjectContext

    private var documents = Set<String>()
    private var maximumHistorySessionCount = 0

    private init() {
        historyMOC = Self.initializeCoreData()

        maximumHistorySessionCount = maxItemCountPref()
    }

    func maxItemCountPref() -> Int {
        let maxItemCount = CommonPrefs.shared.number(
            forKey: .History.maximumHistoryCount,
            Self.defaultMaxItemsCount
        ).intValue

        if maxItemCount >= 0 {
            return maxItemCount
        }
        return Self.defaultMaxItemsCount
    }

    func add(document: VDDocument) {
        update(session: document, closeDocument: false)
    }

    // Update the document and close it (if closeDocument is true)
    func update(
        document: VDDocument,
        closeDocument: Bool
    ) {
        // documents loaded from disk aren't handled by history
        // so they aren't present on self.documents dictionary
        if documents.contains(document.uuid) {
            update(session: document, closeDocument: closeDocument)
        }
    }

    func update(
        session document: VDDocument,
        closeDocument: Bool
    ) {
        historyMOC.performAndWait {
            setSession(document: document)

            if closeDocument {
                documents.remove(document.uuid)
            }
        }
    }

    func setSession(document: VDDocument) {
        MainActor.assumeIsolated {
            guard let sessionDiff = document.sessionDiff,
                  let leftPath = sessionDiff.leftPath,
                  let rightPath = sessionDiff.rightPath else {
                return
            }
            // if we are adding a new document history will be nil
            // if we are updating and left or right path has been changed then history will be nil, too.
            // don't overwrite the session if the paths are changed but create a new one
            guard let history = findBy(leftPath: leftPath, rightPath: rightPath) ?? createNewHistory() else {
                return
            }

            history.fill(with: sessionDiff)
            do {
                try historyMOC.save()
            } catch {
                Logger.general.error("Unable to save history \(error)")
            }
            documents.insert(document.uuid)
        }
    }

    func createNewHistory() -> HistoryEntity? {
        guard let history = NSEntityDescription.insertNewObject(
            forEntityName: HistoryEntity.name,
            into: historyMOC
        ) as? HistoryEntity else {
            return nil
        }
        return history
    }

    func containsHistory(
        leftPath: String,
        rightPath: String
    ) -> Bool {
        do {
            let count = try historyMOC.count(
                for: HistoryEntity.searchPathRequest(leftPath: leftPath, rightPath: rightPath)
            )
            return (count == NSNotFound || count == 0) ? false : true
        } catch {}
        return false
    }

    @discardableResult
    func fill(
        sessionDiff: SessionDiff?,
        leftPath: String,
        rightPath: String
    ) -> Bool {
        guard let sessionDiff,
              let history = findBy(leftPath: leftPath, rightPath: rightPath) else {
            return false
        }

        history.fill(sessionDiff: sessionDiff)

        return true
    }

    func openDocument(
        leftPath: String,
        rightPath: String
    ) throws {
        _ = try MainActor.assumeIsolated {
            try VDDocumentController.shared.openDocumentWithBlock { (doc: VDDocument) in
                self.fill(
                    sessionDiff: doc.sessionDiff,
                    leftPath: leftPath,
                    rightPath: rightPath
                )
                self.add(document: doc)
            }
        }
    }

    func findBy(leftPath: String, rightPath: String) -> HistoryEntity? {
        do {
            return try historyMOC.fetch(HistoryEntity.searchPathRequest(leftPath: leftPath, rightPath: rightPath)).first
        } catch {
            Logger.general.error("Error fetching objects: \(error.localizedDescription)")
        }
        return nil
    }

    static func initializeCoreData() -> NSManagedObjectContext {
        guard let modelURL = Bundle.main.url(forResource: "History", withExtension: "momd"),
              let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing Managed Object Model")
        }

        let psc1 = NSPersistentStoreCoordinator(managedObjectModel: mom)
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = psc1

        guard let storeURL = Self.historyConfigPath(),
              let psc = moc.persistentStoreCoordinator else {
            fatalError("Error getting store URL")
        }

        // start a lightweight migration for added/deleted attributes
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
        ]

        do {
            _ = try psc.addPersistentStore(
                type: .sqlite,
                configuration: nil,
                at: storeURL,
                options: options
            )
        } catch let error as NSError {
            fatalError("Error initializing PSC: \(error.localizedDescription)\n\(error.userInfo)")
        }
        return moc
    }

    static func historyConfigPath() -> URL? {
        let historyPath = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        if !FileManager.default.fileExists(atPath: historyPath.osPath) {
            do {
                try FileManager.default.createDirectory(
                    at: historyPath,
                    withIntermediateDirectories: true
                )
            } catch {
                Logger.general.error("Unable to create history directory \(historyPath), reason \(error)")
                return nil
            }
        }
        return historyPath.appendingPathComponent(Self.historyFileName)
    }
}

extension CommonPrefs.Name {
    enum History {
        static let maximumHistoryCount = CommonPrefs.Name(rawValue: "maximumHistorySessionCount")
    }
}
