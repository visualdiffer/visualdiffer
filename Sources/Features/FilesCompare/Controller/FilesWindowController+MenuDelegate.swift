//
//  FilesWindowController+MenuDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController: NSMenuDelegate, NSMenuItemValidation {
    public func menuNeedsUpdate(_ menu: NSMenu) {
        if menu.identifier == .Files.openWithToolbarMenu {
            // preserve root item
            let root = menu.item(at: 0)
            menu.removeAllItems()

            if let root {
                menu.addItem(root)
            }

            if let path = lastUsedView.side == .left ? resolvedLeftPath : resolvedRightPath {
                menu.addMenuItemsForFile(
                    path,
                    openAppAction: #selector(openWithApp),
                    openOtherAppAction: #selector(openWithOther)
                )
            }
        }
    }

    // called for menu bar items
    public func validateMenuItem(_ item: NSMenuItem) -> Bool {
        let action = item.action
        let isLeftView = lastUsedView.side == .left

        if action == #selector(popupOpenWithApp) {
            let url: URL? = if let path = isLeftView ? sessionDiff.leftPath : sessionDiff.rightPath {
                URL(filePath: path)
            } else {
                nil
            }
            item.menu?.setSubmenu(
                NSMenu.appsMenuForFile(
                    url,
                    openAppAction: #selector(openWithApp),
                    openOtherAppAction: #selector(openWithOther)
                ),
                for: item
            )
            return true
        } else if action == #selector(saveFile) {
            item.title = isLeftView ? NSLocalizedString("Save Left File", comment: "") : NSLocalizedString("Save Right File", comment: "")
            return lastUsedView.isDirty
        } else if action == #selector(previousDifference) {
            if let sections = currentDiffResult?.sections {
                return !sections.isEmpty
            }
            return false
        } else if action == #selector(nextDifference) {
            if let sections = currentDiffResult?.sections {
                return !sections.isEmpty
            }
            return false
        } else if action == #selector(copyLinesToLeft) {
            if lastUsedView.side == .right {
                item.isHidden = false
                return !sessionDiff.leftReadOnly && self.leftView.isEditAllowed
            } else {
                item.isHidden = true
                return false
            }
        } else if action == #selector(copyLinesToRight) {
            if isLeftView {
                item.isHidden = false
                return !sessionDiff.rightReadOnly && self.rightView.isEditAllowed
            } else {
                item.isHidden = true
                return false
            }
        } else if action == #selector(deleteLines) {
            if isLeftView {
                item.title = NSLocalizedString("Delete Lines from Left", comment: "")
                return !sessionDiff.leftReadOnly && self.leftView.isEditAllowed
            } else {
                item.title = NSLocalizedString("Delete Lines from Right", comment: "")
                return !sessionDiff.rightReadOnly && self.rightView.isEditAllowed
            }
        } else if action == #selector(pasteLinesToClipboard) || action == #selector(cutToClipboard) {
            if self.scopeBar.showLinesFilter == .all {
                if isLeftView {
                    return !sessionDiff.leftReadOnly && self.leftView.isEditAllowed
                } else {
                    return !sessionDiff.rightReadOnly && self.rightView.isEditAllowed
                }
            }
            return false
        } else if action == #selector(setLeftReadOnly) {
            item.state = sessionDiff.leftReadOnly ? .on : .off
            return true
        } else if action == #selector(setRightReadOnly) {
            item.state = sessionDiff.rightReadOnly ? .on : .off
            return true
        } else if action == #selector(toggleDetails) {
            item.title = self.linesDetailView.isHidden
                ? NSLocalizedString("Show Details", comment: "")
                : NSLocalizedString("Hide Details", comment: "")
            return true
        } else if action == #selector(previousDifferenceFiles)
            || action == #selector(nextDifferenceFiles) {
            return (document as? VDDocument)?.parentSession != nil
        } else if action == #selector(toggleWordWrap) {
            item.state = rowHeightCalculator.isWordWrapEnabled ? .on : .off
            return true
        }
        return true
    }
}
