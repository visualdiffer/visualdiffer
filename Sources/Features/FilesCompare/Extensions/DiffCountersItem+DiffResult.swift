//
//  DiffCountersItem+DiffResult.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/06/15.
//  Copyright (c) 2015 visualdiffer.com
//

extension DiffCountersItem {
    static func diffCounter(withResult result: DiffResult) -> [DiffCountersItem] {
        var items = [DiffCountersItem]()
        let summary = result.summary

        if summary.deleted > 0 {
            let count = String.localizedStringWithFormat(NSLocalizedString("%ld deleted", comment: ""), summary.deleted)
            if let color = DiffChangeType.deleted.colors?.text {
                items.append(diffCounterItem(withText: count, color: color))
            }
        }
        if summary.added > 0 {
            let count = String.localizedStringWithFormat(NSLocalizedString("%ld added", comment: ""), summary.added)
            if let color = DiffChangeType.added.colors?.text {
                items.append(diffCounterItem(withText: count, color: color))
            }
        }
        if summary.changed > 0 {
            let count = String.localizedStringWithFormat(NSLocalizedString("%ld changed", comment: ""), summary.changed)
            if let color = DiffChangeType.changed.colors?.text {
                items.append(diffCounterItem(withText: count, color: color))
            }
        }
        if summary.matching > 0 {
            let count = String.localizedStringWithFormat(NSLocalizedString("%ld identical", comment: ""), summary.matching)
            if let color = DiffChangeType.matching.colors?.text {
                items.append(diffCounterItem(withText: count, color: color))
            }
        }

        return items
    }
}
