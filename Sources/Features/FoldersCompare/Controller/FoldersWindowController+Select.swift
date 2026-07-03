//
//  FoldersWindowController+Select.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

public struct SelectionSide: OptionSet, Sendable {
    public let rawValue: Int

    public static let left = SelectionSide(rawValue: 1 << 0)
    public static let right = SelectionSide(rawValue: 1 << 1)
    public static let both: SelectionSide = [.left, right]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(menuItem: NSMenuItem) {
        rawValue = menuItem.tag
    }

    public init(displaySide: DisplaySide) {
        rawValue = (displaySide == .left ? Self.left : Self.right).rawValue
    }
}

extension FoldersWindowController {
    private var isShiftKeyDown: Bool {
        NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
    }

    @objc
    func selectNewer(_ sender: AnyObject) {
        guard let sender = sender as? NSMenuItem else {
            return
        }

        select(side: SelectionSide(menuItem: sender), byExtendingSelection: isShiftKeyDown) {
            $0.findFiles(ofType: .changed)
        }
    }

    @objc
    func selectOrphans(_ sender: AnyObject) {
        guard let sender = sender as? NSMenuItem else {
            return
        }

        select(side: SelectionSide(menuItem: sender), byExtendingSelection: isShiftKeyDown) {
            $0.findFiles(ofType: .orphan)
        }
    }

    @objc
    func selectAllBothSides(_ sender: AnyObject) {
        leftView.selectAll(sender)
        rightView.selectAll(sender)
    }

    @objc
    func selectAllFiles(_ sender: AnyObject) {
        guard let sender = sender as? NSMenuItem else {
            return
        }

        select(side: resolvedSide(from: sender), byExtendingSelection: isShiftKeyDown) {
            $0.findFiles()
        }
    }

    @objc
    func selectAllFolders(_ sender: AnyObject) {
        guard let sender = sender as? NSMenuItem else {
            return
        }

        select(side: resolvedSide(from: sender), byExtendingSelection: isShiftKeyDown) {
            $0.findFolders()
        }
    }

    @objc
    func invertSelection(_ sender: AnyObject) {
        guard let sender = sender as? NSMenuItem else {
            return
        }

        let side = SelectionSide(menuItem: sender)

        if side.contains(.both) {
            leftView.invertSelection()
            rightView.invertSelection()
        } else {
            // use the lastUsedView not a specific side
            lastUsedView.invertSelection()
        }
    }

    private func select(
        side: SelectionSide,
        byExtendingSelection: Bool,
        matching: (VisibleItem) -> [VisibleItem]
    ) {
        let leftRoot = leftVisibleItems

        if side.contains(.left),
           let leftRoot {
            leftView.select(visibleItems: matching(leftRoot), byExtendingSelection: byExtendingSelection)
        }
        if side.contains(.right),
           let rightRoot = leftRoot?.linkedItem {
            rightView.select(visibleItems: matching(rightRoot), byExtendingSelection: byExtendingSelection)
        }
    }

    private func resolvedSide(from sender: NSMenuItem) -> SelectionSide {
        SelectionSide(menuItem: sender) == .both ? .both : SelectionSide(displaySide: lastUsedView.side)
    }
}
