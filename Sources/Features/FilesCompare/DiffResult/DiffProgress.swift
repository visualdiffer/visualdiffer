//
//  DiffProgress.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/09/26.
//  Copyright (c) 2026 visualdiffer.com
//

// reports how far a comparison went as a percentage of the processed lines
//
// the handler is notified only when the percentage grows, so the reported value never
// goes backwards and the notifications cannot weigh on the comparison
final class DiffProgress {
    static let maxPercentage = 100

    private let handler: (Int) -> Void

    private var total = 1
    private var percentage = 0

    init(handler: @escaping (Int) -> Void) {
        self.handler = handler
    }

    func begin(total: Int) {
        self.total = max(total, 1)
    }

    func report(processed: Int) {
        let value = Self.maxPercentage * min(processed, total) / total

        if value > percentage {
            percentage = value
            handler(value)
        }
    }
}
