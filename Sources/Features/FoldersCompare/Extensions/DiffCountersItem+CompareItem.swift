//
//  DiffCountersItem+CompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/06/15.
//  Copyright (c) 2015 visualdiffer.com
//

extension DiffCountersItem {
    static func diffCounter(
        withItem compareItem: CompareItem,
        options: ComparatorOptions
    ) -> [DiffCountersItem] {
        let leftOrphans = compareItem.orphanFiles
        let rightOrphans = compareItem.linkedItem?.orphanFiles ?? 0
        let matching = compareItem.matchedFiles
        var changed = 0
        var leftNewer = 0
        var rightNewer = 0

        if options.contains(.timestamp) {
            let linkedOlder = compareItem.linkedItem?.olderFiles ?? 0
            let linkedChanged = compareItem.linkedItem?.changedFiles ?? 0

            if compareItem.changedFiles > 0, linkedOlder > 0 {
                leftNewer = linkedOlder
            }
            if linkedChanged > 0, compareItem.olderFiles > 0 {
                rightNewer = compareItem.olderFiles
            }
            // subtract files already classified as left newer to avoid counting the same difference twice
            changed = compareItem.changedFiles - leftNewer
        } else {
            changed = compareItem.changedFiles
        }

        var items = [DiffCountersItem]()

        add(
            fileCount: leftOrphans,
            format: NSLocalizedString("%ld %lu orphans", comment: "4 left/right orphans"),
            side: .left,
            type: .orphan,
            items: &items
        )
        add(
            fileCount: leftNewer,
            format: NSLocalizedString("%ld %lu newer", comment: "4 left/right newer"),
            side: .left,
            type: .newer,
            items: &items
        )
        add(
            fileCount: rightOrphans,
            format: NSLocalizedString("%ld %lu orphans", comment: "4 left/right orphans"),
            side: .right,
            type: .orphan,
            items: &items
        )
        add(
            fileCount: rightNewer,
            format: NSLocalizedString("%ld %lu newer", comment: "4 left/right newer"),
            side: .right,
            type: .newer,
            items: &items
        )
        add(
            fileCount: changed,
            format: NSLocalizedString("%ld changed", comment: ""),
            side: .left,
            type: .changed,
            items: &items
        )
        add(
            fileCount: matching,
            format: NSLocalizedString("%ld same", comment: ""),
            side: .left,
            type: .same,
            items: &items
        )
        if compareItem.summary.hasMetadataTags || compareItem.mismatchingTags > 0 {
            add(
                fileCount: compareItem.mismatchingTags + (compareItem.summary.hasMetadataTags ? 1 : 0),
                format: NSLocalizedString("%ld mismatching tags", comment: ""),
                side: .left,
                type: .mismatchingTags,
                items: &items
            )
        }
        if compareItem.summary.hasMetadataLabels || compareItem.mismatchingLabels > 0 {
            add(
                fileCount: compareItem.mismatchingLabels + (compareItem.summary.hasMetadataLabels ? 1 : 0),
                format: NSLocalizedString("%ld mismatching labels", comment: ""),
                side: .left,
                type: .mismatchingLabels,
                items: &items
            )
        }
        if let item = items.last, compareItem.parent != nil {
            let fileName = compareItem.isValidFile ? compareItem.fileName : compareItem.linkedItem?.fileName
            item.text = String.localizedStringWithFormat(
                NSLocalizedString("%@ for '%@'", comment: ""),
                item.text,
                fileName ?? "<<Unknown>>"
            ) as NSString
        }

        return items
    }

    private static func add(
        fileCount: Int,
        format: String,
        side: DisplaySide,
        type: CompareChangeType,
        items: inout [DiffCountersItem]
    ) {
        guard fileCount > 0 else {
            return
        }
        let text = String.localizedStringWithFormat(format, fileCount, side.rawValue)
        if let color = CommonPrefs.shared.changeTypeColor(type)?.text {
            items.append(diffCounterItem(withText: text, color: color))
        }
    }
}
