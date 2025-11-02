//
//  FoldersOutlineView+DifferenceNavigator.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/02/21.
//  Copyright (c) 2021 visualdiffer.com
//

struct DifferenceNavigator: OptionSet {
    let rawValue: Int

    static let previous = DifferenceNavigator(rawValue: 1 << 0)
    static let next = DifferenceNavigator(rawValue: 1 << 1)
    static let wrap = DifferenceNavigator(rawValue: 1 << 2)
    static let traverseFolders = DifferenceNavigator(rawValue: 1 << 3)
    static let centerInWindow = DifferenceNavigator(rawValue: 1 << 4)
}

extension FoldersOutlineView {
    func moveToDifference(
        options: DifferenceNavigator,
        didWrap: inout Bool
    ) -> VisibleItem? {
        let foundItem: VisibleItem? = if options.contains(.next) {
            findNextDifference(options: options, didWrap: &didWrap)
        } else if options.contains(.previous) {
            findPreviousDifference(options: options, didWrap: &didWrap)
        } else {
            nil
        }
        guard let foundItem else {
            return nil
        }
        expandParents(of: foundItem)
        select(
            visibleItems: [foundItem],
            scrollToFirst: true,
            center: options.contains(.centerInWindow),
            selectLinked: true
        )
        return foundItem
    }

    private func findNextDifference(
        options: DifferenceNavigator,
        didWrap: inout Bool
    ) -> VisibleItem? {
        var row = selectedRow

        if row < 0 {
            row = 0
        }

        let wrapAround = options.contains(.wrap)
        let traverseSubfolders = options.contains(.traverseFolders)
        guard let from = item(atRow: row) as? VisibleItem else {
            return nil
        }
        var count: Int

        if wrapAround {
            count = numberOfRows
        } else {
            // determine if we can move from last row
            if row == numberOfRows - 1 {
                if from.item.isFile {
                    return nil
                }
                if !traverseSubfolders {
                    return nil
                }
            }
            count = numberOfRows - row
        }

        // If folders must **NOT* be traversed or the current item is a file then go to next row
        // This prevents to find the current row
        if !traverseSubfolders || from.item.isFile {
            row += 1
        }
        let foundItem = findDifference(
            from,
            startRow: row,
            count: count,
            traverseSubfolders: traverseSubfolders,
            findNext: true,
            didWrap: &didWrap
        )
        return foundItem == from ? nil : foundItem
    }

    private func findPreviousDifference(
        options: DifferenceNavigator,
        didWrap: inout Bool
    ) -> VisibleItem? {
        let wrapAround = options.contains(.wrap)
        let traverseSubfolders = options.contains(.traverseFolders)
        var row = selectedRow
        var from: VisibleItem?
        var count: Int

        if row < 0 {
            row = 0
        }

        if wrapAround {
            if row == 0 {
                from = item(atRow: 0) as? VisibleItem
                row = -1
            } else {
                from = item(atRow: row) as? VisibleItem
                row -= 1
            }
            count = numberOfRows
        } else {
            if row == 0 {
                return nil
            }
            from = item(atRow: row) as? VisibleItem
            count = row
            row -= 1
        }

        guard let from else {
            return nil
        }

        let foundItem = findDifference(
            from,
            startRow: row,
            count: count,
            traverseSubfolders: traverseSubfolders,
            findNext: false,
            didWrap: &didWrap
        )
        return foundItem == from ? nil : foundItem
    }

    // swiftlint:disable:next function_parameter_count
    private func findDifference(
        _ rootItem: VisibleItem,
        startRow row: Int,
        count: Int,
        traverseSubfolders: Bool,
        findNext: Bool,
        didWrap: inout Bool
    ) -> VisibleItem? {
        let sign = findNext ? 1 : -1
        var index = row
        var found: VisibleItem?
        didWrap = false
        var from = rootItem

        for _ in 0 ..< count {
            if index < 0 {
                index = numberOfRows - 1
                didWrap = true
            } else if index >= numberOfRows {
                index = 0
                didWrap = true
            }
            guard let item = item(atRow: index) as? VisibleItem else {
                break
            }

            found = findDifference(
                for: item,
                relativeTo: from,
                traverseSubfolders: traverseSubfolders,
                findNext: findNext
            )
            if found != nil {
                break
            }
            index += sign
            from = item
        }
        return found
    }

    func findDifference(
        for rootItem: VisibleItem,
        relativeTo relativeItem: VisibleItem,
        traverseSubfolders: Bool,
        findNext: Bool
    ) -> VisibleItem? {
        let item = rootItem.item

        if !item.hasDifferences {
            return nil
        }

        if item.isFile {
            return rootItem
        }

        if !item.isFolder {
            return nil
        }

        // if traverseSubfolders is false return the item only if it's a leaf
        // no matters if children contain differences
        if !traverseSubfolders, !isItemExpanded(rootItem) {
            return rootItem
        }

        // the relative item is child of 'self' so the parent has been already visited
        if relativeItem.item.parent == item {
            return nil
        }

        let count = rootItem.children.count

        if count == 0 {
            // to avoid 'stay on selected item forever' move to next
            if findNext, relativeItem == rootItem {
                return nil
            }
            return rootItem
        }

        var sign: Int
        var index: Int

        if findNext {
            sign = 1
            index = 0
        } else {
            sign = -1
            index = count - 1
        }

        for _ in 0 ..< count {
            let child = rootItem.children[index]
            let foundItem = findDifference(
                for: child,
                relativeTo: rootItem,
                traverseSubfolders: traverseSubfolders,
                findNext: findNext
            )
            if foundItem != nil {
                return foundItem
            }
            index += sign
        }

        return nil
    }
}
