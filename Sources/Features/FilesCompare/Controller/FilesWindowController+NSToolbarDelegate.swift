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
        static let differenceNavigation = NSToolbarItem.Identifier("DifferenceNavigation")
        static let prevDifferenceFiles = NSToolbarItem.Identifier("PrevDifferenceFiles")
        static let nextDifferenceFiles = NSToolbarItem.Identifier("NextDifferenceFiles")
        static let fileNavigation = NSToolbarItem.Identifier("FileNavigation")
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
    @objc
    public func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .Files.differenceNavigation,
            .space,
            .Files.copyLines,
            .space,
            .Files.fileNavigation,
            .Files.sessionPreferences,
        ]
    }

    @objc
    public func toolbarAllowedItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .space,
            .flexibleSpace,
            .Files.differenceNavigation,
            .Files.copyLines,
            .Files.fileNavigation,
            .Files.openWith,
            .Files.showInFinder,
            .Files.wordWrap,
            .Files.sessionPreferences,
        ]
    }

    @objc
    public func toolbarWillAddItem(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? NSToolbarItem else {
            return
        }

        updateToolbarButton(item)

        if item.itemIdentifier == .Files.openWith {
            item.view?.menu?.delegate = self
        }
    }

    @objc
    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == .Files.differenceNavigation {
            return toolbar.makeSegmentedItemGroup(
                identifier: itemIdentifier,
                label: NSLocalizedString("Differences", comment: ""),
                subitemIdentifiers: [.Files.nextDifference, .Files.prevDifference],
                willBeInsertedIntoToolbar: flag
            )
        } else if itemIdentifier == .Files.fileNavigation {
            return toolbar.makeSegmentedItemGroup(
                identifier: itemIdentifier,
                label: NSLocalizedString("Files with Differences", comment: ""),
                subitemIdentifiers: [.Files.nextDifferenceFiles, .Files.prevDifferenceFiles],
                willBeInsertedIntoToolbar: flag
            )
        } else if itemIdentifier == .Files.copyLines {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Copy Lines", comment: ""),
                tooltip: NSLocalizedString("Copy Lines", comment: ""),
                image: VDSymbol.Toolbar.copyLinesLeft.image(),
                target: self,
                action: #selector(copyLines)
            )
        } else if itemIdentifier == .Files.prevDifference {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Prev Difference", comment: ""),
                tooltip: NSLocalizedString("Go to previous difference", comment: ""),
                image: VDSymbol.Toolbar.prevDifference.image(),
                target: self,
                action: #selector(previousDifference)
            )
        } else if itemIdentifier == .Files.nextDifference {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Next Difference", comment: ""),
                tooltip: NSLocalizedString("Go to next difference", comment: ""),
                image: VDSymbol.Toolbar.nextDifference.image(),
                target: self,
                action: #selector(nextDifference)
            )
        } else if itemIdentifier == .Files.prevDifferenceFiles {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Previous File", comment: ""),
                tooltip: NSLocalizedString("Go to previous file with differences", comment: ""),
                image: VDSymbol.Asset.prevFile.image(),
                target: self,
                action: #selector(previousDifferenceFiles)
            )
        } else if itemIdentifier == .Files.nextDifferenceFiles {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Next File", comment: ""),
                tooltip: NSLocalizedString("Go to next file with differences", comment: ""),
                image: VDSymbol.Asset.nextFile.image(),
                target: self,
                action: #selector(nextDifferenceFiles)
            )
        } else if itemIdentifier == .Files.openWith {
            return .createOpenWithPopup(
                identifier: itemIdentifier,
                menuIdentifier: .Files.openWithToolbarMenu,
                target: self,
                action: #selector(popupOpenWithApp),
                menuDelegate: self
            )
        } else if itemIdentifier == .Files.showInFinder {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Show in Finder", comment: ""),
                tooltip: NSLocalizedString("Show in Finder", comment: ""),
                image: VDSymbol.Toolbar.showInFinder.image(),
                target: self,
                action: #selector(showInFinder)
            )
        } else if itemIdentifier == .Files.sessionPreferences {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Session Settings", comment: ""),
                tooltip: NSLocalizedString("Edit Session Settings", comment: ""),
                image: VDSymbol.Toolbar.sessionPreferences.image(),
                target: self,
                action: #selector(openSessionSettingsSheet)
            )
        } else if itemIdentifier == .Files.wordWrap {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Word Wrap", comment: ""),
                tooltip: NSLocalizedString("Word Wrap", comment: ""),
                image: VDSymbol.Toolbar.wordWrapOff.image(),
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
            return canMoveToDifference(
                gotoNext: false,
                moveToFile: CommonPrefs.shared.fileAutoAdvanceWhenNoMoreDifferences
            )
        } else if item.itemIdentifier == .Files.nextDifference {
            return canMoveToDifference(
                gotoNext: true, moveToFile:
                CommonPrefs.shared.fileAutoAdvanceWhenNoMoreDifferences
            )
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

    @MainActor
    func updateToolbarButton(_ item: NSToolbarItem) {
        if item.itemIdentifier == .Files.wordWrap {
            let symbol: VDSymbol.Toolbar = rowHeightCalculator.isWordWrapEnabled ? .wordWrapOn : .wordWrapOff
            item.image = symbol.image()
            return
        }
        switch lastUsedView.side {
        case .left:
            if item.itemIdentifier == .Files.copyLines {
                item.image = VDSymbol.Toolbar.copyLinesRight.image()
            }
        case .right:
            if item.itemIdentifier == .Files.copyLines {
                item.image = VDSymbol.Toolbar.copyLinesLeft.image()
            }
        }
    }

    @MainActor
    func updateToolbar() {
        guard let items = window?.toolbar?.visibleItems else {
            return
        }

        for item in items {
            updateToolbarButton(item)
        }
    }
}
