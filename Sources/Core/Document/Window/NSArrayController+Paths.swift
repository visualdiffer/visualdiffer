//
//  NSArrayController+Paths.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension NSArrayController {
    convenience init(forUserDefault userDefault: String) {
        self.init()

        avoidsEmptySelection = true
        preservesSelection = true
        selectsInsertedObjects = true
        clearsFilterPredicateOnInsertion = true
        isEditable = true
        objectClass = NSMutableArray.self

        bind(
            NSBindingName.contentArray,
            to: NSUserDefaultsController.shared,
            withKeyPath: String(format: "values.%@", userDefault),
            options: [NSBindingOption.continuouslyUpdatesValue: true]
        )
    }

    @MainActor func addPath(_ newPath: String) {
        guard let arrangedObjects = arrangedObjects as? [String] else {
            return
        }
        // move last used on top
        if let index = arrangedObjects.firstIndex(of: newPath) {
            remove(atArrangedObjectIndex: index)
        }
        insert(newPath, atArrangedObjectIndex: 0)
        // Set maximum saved items
        let docController = NSDocumentController.shared
        let maxCount = docController.maximumRecentDocumentCount
        let len = arrangedObjects.count - maxCount
        if len > 0 {
            let indexSet = IndexSet(maxCount ..< arrangedObjects.count)
            remove(atArrangedObjectIndexes: indexSet)
        }
    }
}
