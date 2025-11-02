//
//  NSManagedObjectContext+Helpers.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/10/15.
//  Copyright (c) 2015 visualdiffer.com
//

extension NSManagedObjectContext {
    ///
    /// Wrap the block around disable/enable undo registration pair
    ///
    /// Parameters:
    /// - block: the code to execute with registration disabled
    @MainActor func updateWithoutRecordingModifications(_ block: () -> Void) {
        undoManager?.disableUndoRegistration()

        block()

        processPendingChanges()
        undoManager?.enableUndoRegistration()
    }
}
