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
}

extension FoldersWindowController {
    @objc
    func selectNewer(_ sender: AnyObject) {
        guard let sender = sender as? NSMenuItem else {
            return
        }
        let side = SelectionSide(menuItem: sender)

        if side.contains(.left) {
            leftView.selectBy(type: .changed)
        }
        if side.contains(.right) {
            rightView.selectBy(type: .changed)
        }
    }

    @objc
    func selectOrphans(_ sender: AnyObject) {
        guard let sender = sender as? NSMenuItem else {
            return
        }
        let side = SelectionSide(menuItem: sender)

        if side.contains(.left) {
            leftView.selectBy(type: .orphan)
        }
        if side.contains(.right) {
            rightView.selectBy(type: .orphan)
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
        let side = SelectionSide(menuItem: sender)

        let isShiftDown = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false

        if side.contains(.both) {
            leftView.selectAll(files: true, folders: false, byExtendingSelection: isShiftDown)
            rightView.selectAll(files: true, folders: false, byExtendingSelection: isShiftDown)
        } else {
            // use the lastUsedView not a specific side
            lastUsedView.selectAll(files: true, folders: false, byExtendingSelection: isShiftDown)
        }
    }

    @objc
    func selectAllFolders(_ sender: AnyObject) {
        guard let sender = sender as? NSMenuItem else {
            return
        }
        let side = SelectionSide(menuItem: sender)

        let isShiftDown = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false

        if side.contains(.both) {
            leftView.selectAll(files: false, folders: true, byExtendingSelection: isShiftDown)
            rightView.selectAll(files: false, folders: true, byExtendingSelection: isShiftDown)
        } else {
            // use the lastUsedView not a specific side
            lastUsedView.selectAll(files: false, folders: true, byExtendingSelection: isShiftDown)
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
}
