//
//  MockItemComparatorDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

@testable import VisualDiffer

class MockItemComparatorDelegate: ItemComparatorDelegate {
    var isRunning: Bool

    init(isRunning: Bool = true) {
        self.isRunning = isRunning
    }

    func isRunning(_: ItemComparator) -> Bool {
        isRunning
    }
}
