//
//  MainThreadComparatorDelegateBridge.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

/**
 * This bridge is used to call on main thread all ItemComparatorDelegate methods
 */
class MainThreadComparatorDelegateBridge: ItemComparatorDelegate {
    private weak var controller: FoldersWindowController?

    init(_ controller: FoldersWindowController) {
        self.controller = controller
    }

    func isRunning(_: ItemComparator) -> Bool {
        guard let controller else {
            return false
        }

        return DispatchQueue.main.sync {
            controller.running
        }
    }
}
