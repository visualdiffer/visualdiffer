//
//  DescriptionOutlineNode+FolderCompareInfo.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/02/12.
//  Copyright (c) 2012 visualdiffer.com
//

extension DescriptionOutlineNode {
    private func appendChild(
        pattern: String,
        rootPath: String,
        items: [CompareItem],
        side: DisplaySide
    ) {
        if items.isEmpty {
            return
        }
        let path = String.localizedStringWithFormat(pattern, items.count, side.rawValue)
        children.append(DescriptionOutlineNode(
            relativePath: path,
            items: items,
            rootPath: rootPath
        ))
    }

    func addCompareGroup(
        leftRoot: CompareItem,
        comparatorOptions: ComparatorOptions
    ) {
        var leftOrphanFiles = [CompareItem]()
        var rightOrphanFiles = [CompareItem]()
        var matchesFiles = [CompareItem]()
        var leftNewerFiles = [CompareItem]()
        var rightNewerFiles = [CompareItem]()

        // if path is nil the associated counts will be 0
        // so it's safe to use the default to empty string because it will never be used
        let leftPath = leftRoot.path ?? ""
        let rightPath = leftRoot.linkedItem?.path ?? ""

        leftRoot.compareInfo(
            leftOrphanFiles: &leftOrphanFiles,
            rightOrphanFiles: &rightOrphanFiles,
            matchesFiles: &matchesFiles,
            newerLeftFiles: &leftNewerFiles,
            newerRightFiles: &rightNewerFiles
        )

        appendChild(
            pattern: NSLocalizedString("%ld %lu orphans", comment: "4 left/right orphans"),
            rootPath: leftPath,
            items: leftOrphanFiles,
            side: .left
        )
        appendChild(
            pattern: NSLocalizedString("%ld %lu orphans", comment: "4 left/right orphans"),
            rootPath: rightPath,
            items: rightOrphanFiles,
            side: .right
        )

        if comparatorOptions.contains(.timestamp) {
            appendChild(
                pattern: NSLocalizedString("%ld %lu newer", comment: "4 left/right newer"),
                rootPath: leftPath,
                items: leftNewerFiles,
                side: .left
            )
            appendChild(
                pattern: NSLocalizedString("%ld %lu newer", comment: "4 left/right newer"),
                rootPath: rightPath,
                items: rightNewerFiles,
                side: .right
            )
        } else {
            appendChild(
                pattern: NSLocalizedString("%ld different", comment: ""),
                rootPath: leftPath,
                items: leftNewerFiles,
                side: .left
            )
        }

        appendChild(
            pattern: NSLocalizedString("%ld same", comment: ""),
            rootPath: leftPath,
            items: matchesFiles,
            side: .left
        )
    }
}
