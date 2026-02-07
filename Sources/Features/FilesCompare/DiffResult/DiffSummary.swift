//
//  DiffSummary.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

struct DiffSummary {
    var matching = 0
    var added = 0
    var deleted = 0
    var changed = 0

    mutating func reset() {
        matching = 0
        added = 0
        deleted = 0
        changed = 0
    }

    mutating func refresh(_ lines: [DiffLine]) {
        reset()

        for line in lines {
            switch line.type {
            case .matching:
                matching += 1
            case .changed:
                changed += 1
            case .deleted:
                deleted += 1
            case .missing:
                added += 1
            case .added:
                // does nothing
                break
            }
        }
    }
}

extension DiffSummary: Equatable {
    // swiftformat:disable redundantEquatable
    static func == (lhs: DiffSummary, rhs: DiffSummary) -> Bool {
        lhs.matching == rhs.matching &&
            lhs.added == rhs.added &&
            lhs.deleted == rhs.deleted &&
            lhs.changed == rhs.changed
    }
}
