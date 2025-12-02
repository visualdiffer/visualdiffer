//
//  FilesWindowController+NSToolbarDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension NSToolbarItem.Identifier {
    enum Files {
        static let copyLines = NSToolbarItem.Identifier("CopyLines")
        static let prevDifference = NSToolbarItem.Identifier("PrevDifference")
        static let nextDifference = NSToolbarItem.Identifier("NextDifference")
        static let prevDifferenceFiles = NSToolbarItem.Identifier("PrevDifferenceFiles")
        static let nextDifferenceFiles = NSToolbarItem.Identifier("NextDifferenceFiles")
        static let openWith = NSToolbarItem.Identifier("OpenWith")
        static let showInFinder = NSToolbarItem.Identifier("ShowInFinder")
        static let sessionPreferences = NSToolbarItem.Identifier("SessionPreferences")
        static let wordWrap = NSToolbarItem.Identifier("WordWrap")
    }
}

extension NSUserInterfaceItemIdentifier {
    enum Files {
        static let openWithToolbarMenu = NSUserInterfaceItemIdentifier("FileOpenWithToolbarMenuIdentifier")
    }
}

extension FilesWindowController: NSToolbarDelegate, NSToolbarItemValidation {
    @objc public func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .Files.nextDifference,
            .Files.prevDifference,
            .space,
            .Files.copyLines,
            .space,
            .Files.nextDifferenceFiles,
            .Files.prevDifferenceFiles,
            .Files.sessionPreferences,
        ]
    }

    @objc public func toolbarAllowedItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .space,
            .flexibleSpace,
            .Files.nextDifference,
            .Files.prevDifference,
            .Files.copyLines,
            .Files.nextDifferenceFiles,
            .Files.prevDifferenceFiles,
            .Files.openWith,
            .Files.showInFinder,
            .Files.wordWrap,
            .Files.sessionPreferences,
        ]
    }

    @objc public func toolbarWillAddItem(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? NSToolbarItem else {
            return
        }
        updateToolbarButton(item)

        if item.itemIdentifier == .Files.openWith {
            item.view?.menu?.delegate = self
        }
    }

    @objc public func toolbar(_: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar _: Bool) -> NSToolbarItem? {
        if itemIdentifier == .Files.copyLines {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Copy Lines", comment: ""),
                tooltip: NSLocalizedString("Copy Lines", comment: ""),
                image: NSImage(named: VDImageNameCopyLinesLeft),
                target: self,
                action: #selector(copyLines)
            )
        } else if itemIdentifier == .Files.prevDifference {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Prev Difference", comment: ""),
                tooltip: NSLocalizedString("Go to Previous Difference", comment: ""),
                image: NSImage(named: VDImageNamePrev),
                target: self,
                action: #selector(previousDifference)
            )
        } else if itemIdentifier == .Files.nextDifference {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Next Difference", comment: ""),
                tooltip: NSLocalizedString("Go to Next Difference", comment: ""),
                image: NSImage(named: VDImageNameNext),
                target: self,
                action: #selector(nextDifference)
            )
        } else if itemIdentifier == .Files.prevDifferenceFiles {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Previous File", comment: ""),
                tooltip: NSLocalizedString("Go to Previous File With Differences", comment: ""),
                image: NSImage(named: VDImageNamePrevFile),
                target: self,
                action: #selector(previousDifferenceFiles)
            )
        } else if itemIdentifier == .Files.nextDifferenceFiles {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Next File", comment: ""),
                tooltip: NSLocalizedString("Go to Next File With Differences", comment: ""),
                image: NSImage(named: VDImageNameNextFile),
                target: self,
                action: #selector(nextDifferenceFiles)
            )
        } else if itemIdentifier == .Files.openWith {
            let popupButton = NSPopUpButton(
                identifier: .Files.openWithToolbarMenu,
                menuTitle: NSLocalizedString("ToolbarOpenWith", comment: ""),
                menuImage: NSImage(named: VDImageNameOpenWith)
            )
            popupButton.target = self
            popupButton.action = #selector(popupOpenWithApp)
            popupButton.menu?.delegate = self

            let item = CustomValidationToolbarItem(itemIdentifier: itemIdentifier)
                .with(
                    label: NSLocalizedString("Open With", comment: ""),
                    tooltip: NSLocalizedString("Open using selected application", comment: ""),
                    image: NSImage(named: VDImageNameFinder),
                    target: nil,
                    action: nil
                )
            item.view = popupButton

            return item
        } else if itemIdentifier == .Files.showInFinder {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Show in Finder", comment: ""),
                tooltip: NSLocalizedString("Show in Finder", comment: ""),
                image: NSImage(named: VDImageNameFinder),
                target: self,
                action: #selector(showInFinder)
            )
        } else if itemIdentifier == .Files.sessionPreferences {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Session Preferences", comment: ""),
                tooltip: NSLocalizedString("Edit Session Preferences", comment: ""),
                image: NSImage(named: VDImageNamePreferences),
                target: self,
                action: #selector(openSessionSettingsSheet)
            )
        } else if itemIdentifier == .Files.wordWrap {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Word Wrap", comment: ""),
                tooltip: NSLocalizedString("Word Wrap", comment: ""),
                image: NSImage(named: VDImageNameWordWrapOff),
                target: self,
                action: #selector(toggleWordWrap)
            )
        }

        return nil
    }

    open func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        var enabled = true
        let side = lastUsedView.side

        if item.itemIdentifier == .Files.prevDifference {
            guard let sections = currentDiffResult?.sections else {
                return false
            }
            return !sections.isEmpty
        } else if item.itemIdentifier == .Files.nextDifference {
            guard let sections = currentDiffResult?.sections else {
                return false
            }
            return !sections.isEmpty
        } else if item.itemIdentifier == .Files.prevDifferenceFiles
            || item.itemIdentifier == .Files.nextDifferenceFiles {
            return (document as? VDDocument)?.parentSession != nil
        }

        if side == .left {
            if item.itemIdentifier == .Files.copyLines {
                return !sessionDiff.rightReadOnly && rightView.isEditAllowed
            }
        } else if side == .right {
            if item.itemIdentifier == .Files.copyLines {
                return !sessionDiff.leftReadOnly && leftView.isEditAllowed
            }
        }

        let isLeftView = side == .left
        let path = isLeftView ? resolvedLeftPath : resolvedRightPath
        if item.itemIdentifier == .Files.showInFinder {
            enabled = path != nil
        } else if item.itemIdentifier == .Files.openWith {
            enabled = path != nil
        }

        return enabled
    }

    @MainActor func updateToolbarButton(_ item: NSToolbarItem) {
        if item.itemIdentifier == .Files.wordWrap {
            item.image = NSImage(named: rowHeightCalculator.isWordWrapEnabled ? VDImageNameWordWrapOn : VDImageNameWordWrapOff)
            return
        }
        switch lastUsedView.side {
        case .left:
            if item.itemIdentifier == .Files.copyLines {
                item.image = NSImage(named: VDImageNameCopyLinesRight)
            }
        case .right:
            if item.itemIdentifier == .Files.copyLines {
                item.image = NSImage(named: VDImageNameCopyLinesLeft)
            }
        }
    }

    @MainActor func updateToolbar() {
        guard let items = window?.toolbar?.visibleItems else {
            return
        }
        for item in items {
            updateToolbarButton(item)
        }
    }
}
