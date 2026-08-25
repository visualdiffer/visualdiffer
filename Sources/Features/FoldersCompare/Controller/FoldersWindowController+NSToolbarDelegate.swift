//
//  FoldersWindowController+NSToolbarDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension NSToolbarItem.Identifier {
    enum Folders {
        static let comparisonList = NSToolbarItem.Identifier("ComparisonList")
        static let comparison = NSToolbarItem.Identifier("Comparison")
        static let exclusionFilters = NSToolbarItem.Identifier("ExclusionFilters")
        static let refresh = NSToolbarItem.Identifier("Refresh")
        static let expandAllFolders = NSToolbarItem.Identifier("ExpandAllFolders")
        static let collapseAllFolders = NSToolbarItem.Identifier("CollapseAllFolders")
        static let folderExpansion = NSToolbarItem.Identifier("FolderExpansion")
        static let copy = NSToolbarItem.Identifier("Copy")
        static let move = NSToolbarItem.Identifier("Move")
        static let sync = NSToolbarItem.Identifier("Sync")
        static let touch = NSToolbarItem.Identifier("Touch")
        static let sessionPreferences = NSToolbarItem.Identifier("SessionPreferences")
        static let nextDifference = NSToolbarItem.Identifier("NextDifference")
        static let prevDifference = NSToolbarItem.Identifier("PrevDifference")
        static let differenceNavigation = NSToolbarItem.Identifier("DifferenceNavigation")
        static let openWith = NSToolbarItem.Identifier("OpenWith")
        static let showInFinder = NSToolbarItem.Identifier("ShowInFinder")
        static let compareItems = NSToolbarItem.Identifier("CompareItems")
    }
}

extension NSUserInterfaceItemIdentifier {
    enum Folders {
        static let openWithToolbarMenu = NSUserInterfaceItemIdentifier("FolderOpenWithToolbarMenuIdentifier")
    }
}

extension FoldersWindowController: NSToolbarDelegate, NSToolbarItemValidation {
    public func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .Folders.comparison,
            .Folders.folderExpansion,
            .Folders.refresh,
            .space,
            .Folders.copy,
            .Folders.move,
            .space,
            .Folders.sync,
            .Folders.touch,
            .flexibleSpace,
            .Folders.exclusionFilters,
            .Folders.sessionPreferences,
        ]
    }

    public func toolbarAllowedItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .Folders.comparisonList,
            .Folders.comparison,
            .space,
            .flexibleSpace,
            .Folders.exclusionFilters,
            .Folders.refresh,
            .Folders.folderExpansion,
            .Folders.copy,
            .Folders.move,
            .Folders.sync,
            .Folders.touch,
            .Folders.sessionPreferences,
            .Folders.differenceNavigation,
            .Folders.openWith,
            .Folders.showInFinder,
            .Folders.compareItems,
        ]
    }

    public func toolbarWillAddItem(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? NSToolbarItem else {
            return
        }

        updateToolbarButton(item)
    }

    // swiftlint:disable:next function_body_length
    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == .Folders.differenceNavigation {
            return toolbar.makeSegmentedItemGroup(
                identifier: itemIdentifier,
                label: NSLocalizedString("Differences", comment: ""),
                subitemIdentifiers: [.Folders.nextDifference, .Folders.prevDifference],
                willBeInsertedIntoToolbar: flag
            )
        } else if itemIdentifier == .Folders.folderExpansion {
            return toolbar.makeSegmentedItemGroup(
                identifier: itemIdentifier,
                label: NSLocalizedString("Expand/Collapse", comment: ""),
                subitemIdentifiers: [.Folders.expandAllFolders, .Folders.collapseAllFolders],
                willBeInsertedIntoToolbar: flag
            )
        } else if itemIdentifier == .Folders.comparisonList {
            return createComparisonListToolbarPopup(identifier: itemIdentifier)
        } else if itemIdentifier == .Folders.comparison {
            return createComparisonToolbarPopup(identifier: itemIdentifier)
        } else if itemIdentifier == .Folders.exclusionFilters {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Exclusion Filters", comment: ""),
                tooltip: NSLocalizedString("Edit Exclusion File Filters", comment: ""),
                image: VDSymbol.Toolbar.filter.image(),
                target: self,
                action: #selector(openFileFilters)
            )
        } else if itemIdentifier == .Folders.refresh {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Refresh", comment: ""),
                tooltip: NSLocalizedString("Refresh", comment: ""),
                image: VDSymbol.Toolbar.refresh.image(),
                target: self,
                action: #selector(refresh)
            )
        } else if itemIdentifier == .Folders.expandAllFolders {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Expand All", comment: ""),
                tooltip: NSLocalizedString("Expand All Folders", comment: ""),
                image: VDSymbol.Toolbar.expand.image(),
                target: self,
                action: #selector(expandAllFolders)
            )
        } else if itemIdentifier == .Folders.collapseAllFolders {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Collapse All", comment: ""),
                tooltip: NSLocalizedString("Collapse All Folders", comment: ""),
                image: VDSymbol.Toolbar.collapse.image(),
                target: self,
                action: #selector(collapseAllFolders)
            )
        } else if itemIdentifier == .Folders.copy {
            let toolbarItem = NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Copy Files", comment: ""),
                tooltip: NSLocalizedString("Copy Files", comment: ""),
                image: VDSymbol.Toolbar.copyRight.image(),
                target: self,
                action: #selector(copyFiles)
            )
            toolbarItem.tag = CopyFilesTag.fileContents.rawValue
            return toolbarItem
        } else if itemIdentifier == .Folders.move {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Move Files", comment: ""),
                tooltip: NSLocalizedString("Move Files", comment: ""),
                image: VDSymbol.Toolbar.moveRight.image(),
                target: self,
                action: #selector(moveFiles)
            )
        } else if itemIdentifier == .Folders.sync {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Sync Files", comment: ""),
                tooltip: NSLocalizedString("Copy newer and orphan files", comment: ""),
                image: VDSymbol.Toolbar.syncRight.image(),
                target: self,
                action: #selector(syncFiles)
            )
        } else if itemIdentifier == .Folders.touch {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Set Date", comment: ""),
                tooltip: NSLocalizedString("Change date/time", comment: ""),
                image: VDSymbol.Toolbar.dateTime.image(),
                target: self,
                action: #selector(setModificationDate)
            )
        } else if itemIdentifier == .Folders.sessionPreferences {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Session Settings", comment: ""),
                tooltip: NSLocalizedString("Edit Session Settings", comment: ""),
                image: VDSymbol.Toolbar.sessionPreferences.image(),
                target: self,
                action: #selector(openSessionSettingsSheet)
            )
        } else if itemIdentifier == .Folders.nextDifference {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Next Difference", comment: ""),
                tooltip: NSLocalizedString("Go to next difference", comment: ""),
                image: VDSymbol.Toolbar.nextDifference.image(),
                target: self,
                action: #selector(nextDifference)
            )
        } else if itemIdentifier == .Folders.prevDifference {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Prev Difference", comment: ""),
                tooltip: NSLocalizedString("Go to previous difference", comment: ""),
                image: VDSymbol.Toolbar.prevDifference.image(),
                target: self,
                action: #selector(previousDifference)
            )
        } else if itemIdentifier == .Folders.openWith {
            return .createOpenWithPopup(
                identifier: itemIdentifier,
                menuIdentifier: .Folders.openWithToolbarMenu,
                target: self,
                action: #selector(popupOpenWithApp),
                menuDelegate: self
            )
        } else if itemIdentifier == .Folders.showInFinder {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Show in Finder", comment: ""),
                tooltip: NSLocalizedString("Show in Finder", comment: ""),
                image: VDSymbol.Toolbar.showInFinder.image(),
                target: self,
                action: #selector(showInFinder)
            )
        } else if itemIdentifier == .Folders.compareItems {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Compare", comment: ""),
                tooltip: NSLocalizedString("Compare selected files or folders", comment: ""),
                image: VDSymbol.Toolbar.compareItems.image(),
                target: self,
                action: #selector(compareItems)
            )
        }

        return nil
    }

    open func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if running {
            return false
        }

        let fsi = lastUsedView.selectionInfo

        if item.itemIdentifier == .Folders.copy {
            return fsi.validateCopyFiles(sessionDiff)
        }
        if item.itemIdentifier == .Folders.sync {
            return fsi.validateSyncFiles(sessionDiff)
        }
        if item.itemIdentifier == .Folders.move {
            return fsi.validateMoveFiles(sessionDiff)
        }
        if item.itemIdentifier == .Folders.touch {
            return fsi.validateFileTouch(sessionDiff)
        }
        if item.itemIdentifier == .Folders.showInFinder {
            return fsi.validateShowInFinder()
        }
        if item.itemIdentifier == .Folders.openWith {
            var path: String?
            return fsi.validateOpen(withApp: &path)
        }
        if item.itemIdentifier == .Folders.compareItems {
            return fsi.comparableType != nil
        }
        return true
    }

    func updateToolbarButton(_ item: NSToolbarItem) {
        switch lastUsedView.side {
        case .left:
            if item.itemIdentifier == .Folders.copy {
                item.image = VDSymbol.Toolbar.copyRight.image()
            } else if item.itemIdentifier == .Folders.sync {
                item.image = VDSymbol.Toolbar.syncRight.image()
            } else if item.itemIdentifier == .Folders.move {
                item.image = VDSymbol.Toolbar.moveRight.image()
            }
        case .right:
            if item.itemIdentifier == .Folders.copy {
                item.image = VDSymbol.Toolbar.copyLeft.image()
            } else if item.itemIdentifier == .Folders.sync {
                item.image = VDSymbol.Toolbar.syncLeft.image()
            } else if item.itemIdentifier == .Folders.move {
                item.image = VDSymbol.Toolbar.moveLeft.image()
            }
        }
    }

    func updateToolbarTooltip() {
        guard let toolbar = window?.toolbar,
              let visibleItems = toolbar.visibleItems else {
            return
        }

        for item in visibleItems {
            // swiftlint:disable:next for_where
            if item.itemIdentifier == .Folders.comparison {
                item.toolTip = comparatorMethod.description
            }
        }
    }

    func updateComparisonToolbarItems(_ method: ComparatorOptions) {
        // The Objc version of VD used `popupButton.bind(.selectedTag, ... withKeyPath: "comparatorMethod",`
        // and `comparatorMethod` was declared `@objc dynamic` which is not compatible
        // with the Swift version of `ComparatorOptions` so we update by hand

        let comparisonItems: [NSToolbarItem.Identifier] = [
            .Folders.comparison,
            .Folders.comparisonList,
        ]

        window?
            .toolbar?
            .visibleItems?
            .filter { comparisonItems.contains($0.itemIdentifier) }
            .forEach {
                if let popupButton = $0.view as? NSPopUpButton {
                    popupButton.select(popupButton.menu?.item(withTag: method.rawValue))
                }
            }
    }

    private func createComparisonListToolbarPopup(
        identifier: NSToolbarItem.Identifier
    ) -> NSToolbarItem {
        let cell = ComparatorPopUpButtonCell(textCell: "", pullsDown: false)

        let popupButton = NSPopUpButton(frame: .zero, pullsDown: false)
        popupButton.cell = cell
        popupButton.alignment = .left
        popupButton.state = .off
        popupButton.imagePosition = .noImage

        return makeComparisonToolbarItem(identifier: identifier, popupButton: popupButton)
    }

    private func createComparisonToolbarPopup(
        identifier: NSToolbarItem.Identifier
    ) -> NSToolbarItem {
        let menuItem = NSMenuItem()
        menuItem.state = .on
        menuItem.image = VDSymbol.Toolbar.comparisonMethod.image()
        menuItem.isHidden = true
        let cell = ComparatorPopUpButtonCell(textCell: "", pullsDown: true)
        cell.menu?.insertItem(menuItem, at: 0)
        cell.arrowPosition = .arrowAtCenter

        let popupButton = NSPopUpButton(frame: .zero, pullsDown: true)
        popupButton.cell = cell
        popupButton.image = VDSymbol.Toolbar.comparisonMethod.image()
        popupButton.imagePosition = .imageOnly
        popupButton.alignment = .center
        popupButton.state = .on
        popupButton.isBordered = true

        let item = makeComparisonToolbarItem(identifier: identifier, popupButton: popupButton)
        item.toolTip = comparatorMethod.description

        return item
    }

    // shared popup/toolbar-item setup for both comparison variants,
    // the caller configures only the properties that differ between them
    private func makeComparisonToolbarItem(
        identifier: NSToolbarItem.Identifier,
        popupButton: NSPopUpButton
    ) -> CustomValidationToolbarItem {
        popupButton.bezelStyle = .texturedRounded
        popupButton.setButtonType(.momentaryPushIn)
        popupButton.lineBreakMode = .byTruncatingTail
        popupButton.imageScaling = .scaleProportionallyDown
        popupButton.target = self
        popupButton.action = #selector(selectComparison)
        popupButton.select(popupButton.menu?.item(withTag: comparatorMethod.rawValue))

        let item = CustomValidationToolbarItem(itemIdentifier: identifier)
        item.label = NSLocalizedString("Comparison", comment: "")
        item.paletteLabel = NSLocalizedString("Comparison", comment: "")
        item.view = popupButton

        return item
    }
}
