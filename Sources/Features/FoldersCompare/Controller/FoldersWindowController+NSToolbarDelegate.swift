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
        static let copy = NSToolbarItem.Identifier("Copy")
        static let move = NSToolbarItem.Identifier("Move")
        static let sync = NSToolbarItem.Identifier("Sync")
        static let touch = NSToolbarItem.Identifier("Touch")
        static let sessionPreferences = NSToolbarItem.Identifier("SessionPreferences")
        static let nextDifference = NSToolbarItem.Identifier("NextDifference")
        static let prevDifference = NSToolbarItem.Identifier("PrevDifference")
        static let openWith = NSToolbarItem.Identifier("OpenWith")
        static let showInFinder = NSToolbarItem.Identifier("ShowInFinder")
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
            .Folders.expandAllFolders,
            .Folders.collapseAllFolders,
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
            .Folders.expandAllFolders,
            .Folders.collapseAllFolders,
            .Folders.copy,
            .Folders.move,
            .Folders.sync,
            .Folders.touch,
            .Folders.sessionPreferences,
            .Folders.nextDifference,
            .Folders.prevDifference,
            .Folders.openWith,
            .Folders.showInFinder,
        ]
    }

    public func toolbarWillAddItem(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? NSToolbarItem else {
            return
        }
        updateToolbarButton(item)
    }

    // swiftlint:disable:next function_body_length
    public func toolbar(_: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar _: Bool) -> NSToolbarItem? {
        if itemIdentifier == .Folders.comparisonList {
            let cell = ComparatorPopUpButtonCell(textCell: "", pullsDown: false)

            let popupButton = NSPopUpButton(frame: .zero, pullsDown: false)
            popupButton.cell = cell
            popupButton.bezelStyle = .texturedRounded
            popupButton.setButtonType(.momentaryPushIn)
            popupButton.alignment = .left
            popupButton.lineBreakMode = .byTruncatingTail
            popupButton.state = .off
            popupButton.imagePosition = .noImage
            popupButton.imageScaling = .scaleProportionallyDown
            popupButton.target = self
            popupButton.action = #selector(selectComparison)
            popupButton.select(popupButton.menu?.item(withTag: comparatorMethod.rawValue))

            let item = CustomValidationToolbarItem(itemIdentifier: itemIdentifier)
            item.label = NSLocalizedString("Comparison", comment: "")
            item.paletteLabel = NSLocalizedString("Comparison", comment: "")
            item.view = popupButton

            return item
        } else if itemIdentifier == .Folders.comparison {
            let menuItem = NSMenuItem()
            menuItem.state = .on
            menuItem.image = NSImage(named: VDImageNameComparisonMethod)
            menuItem.isHidden = true
            let cell = ComparatorPopUpButtonCell(textCell: "", pullsDown: true)
            cell.menu?.insertItem(menuItem, at: 0)
            cell.arrowPosition = .arrowAtCenter

            let popupButton = NSPopUpButton(frame: .zero, pullsDown: true)
            popupButton.cell = cell
            popupButton.image = NSImage(named: VDImageNameComparisonMethod)
            popupButton.imagePosition = .imageOnly
            popupButton.bezelStyle = .texturedRounded
            popupButton.setButtonType(.momentaryPushIn)
            popupButton.alignment = .center
            popupButton.lineBreakMode = .byTruncatingTail
            popupButton.state = .on
            popupButton.isBordered = true
            popupButton.imageScaling = .scaleProportionallyDown
            popupButton.target = self
            popupButton.action = #selector(selectComparison)
            popupButton.select(popupButton.menu?.item(withTag: comparatorMethod.rawValue))

            let item = CustomValidationToolbarItem(itemIdentifier: itemIdentifier)
            item.label = NSLocalizedString("Comparison", comment: "")
            item.paletteLabel = NSLocalizedString("Comparison", comment: "")
            item.toolTip = comparatorMethod.description
            item.view = popupButton

            return item
        } else if itemIdentifier == .Folders.exclusionFilters {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Exclusion Filters", comment: ""),
                tooltip: NSLocalizedString("Edit Exclusion File Filters", comment: ""),
                image: NSImage(named: VDImageNameFilter),
                target: self,
                action: #selector(openFileFilters)
            )
        } else if itemIdentifier == .Folders.refresh {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Refresh", comment: ""),
                tooltip: NSLocalizedString("Refresh", comment: ""),
                image: NSImage(named: VDImageNameRefresh),
                target: self,
                action: #selector(refresh)
            )
        } else if itemIdentifier == .Folders.expandAllFolders {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Expand All", comment: ""),
                tooltip: NSLocalizedString("Expand All Folders", comment: ""),
                image: NSImage(named: VDImageNameExpand),
                target: self,
                action: #selector(expandAllFolders)
            )
        } else if itemIdentifier == .Folders.collapseAllFolders {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Collapse All", comment: ""),
                tooltip: NSLocalizedString("Collapse All Folders", comment: ""),
                image: NSImage(named: VDImageNameCollapse),
                target: self,
                action: #selector(collapseAllFolders)
            )
        } else if itemIdentifier == .Folders.copy {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Copy Files", comment: ""),
                tooltip: NSLocalizedString("Copy Files", comment: ""),
                image: NSImage(named: VDImageNameCopyRight),
                target: self,
                action: #selector(copyFiles)
            )
        } else if itemIdentifier == .Folders.move {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Move Files", comment: ""),
                tooltip: NSLocalizedString("Move Files", comment: ""),
                image: NSImage(named: VDImageNameMoveRight),
                target: self,
                action: #selector(moveFiles)
            )
        } else if itemIdentifier == .Folders.sync {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Sync Files", comment: ""),
                tooltip: NSLocalizedString("Copy newer and orphan files", comment: ""),
                image: NSImage(named: VDImageNameSyncRight),
                target: self,
                action: #selector(syncFiles)
            )
        } else if itemIdentifier == .Folders.touch {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Set Date", comment: ""),
                tooltip: NSLocalizedString("Change date/time", comment: ""),
                image: NSImage(named: VDImageNameDateTime),
                target: self,
                action: #selector(setModificationDate)
            )
        } else if itemIdentifier == .Folders.sessionPreferences {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Session Preferences", comment: ""),
                tooltip: NSLocalizedString("Edit Session Preferences", comment: ""),
                image: NSImage(named: VDImageNamePreferences),
                target: self,
                action: #selector(openSessionSettingsSheet)
            )
        } else if itemIdentifier == .Folders.nextDifference {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Next Difference", comment: ""),
                tooltip: NSLocalizedString("Go to Next Difference", comment: ""),
                image: NSImage(named: VDImageNameNext),
                target: self,
                action: #selector(nextDifference)
            )
        } else if itemIdentifier == .Folders.prevDifference {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Prev Difference", comment: ""),
                tooltip: NSLocalizedString("Go to Previous Difference", comment: ""),
                image: NSImage(named: VDImageNamePrev),
                target: self,
                action: #selector(previousDifference)
            )
        } else if itemIdentifier == .Folders.openWith {
            let popupButton = NSPopUpButton(
                identifier: .Folders.openWithToolbarMenu,
                menuTitle: NSLocalizedString("ToolbarOpenWith", comment: ""),
                menuImage: NSImage(named: VDImageNameOpenWith)
            )
            popupButton.target = self
            popupButton.action = #selector(popupOpenWithApp)
            popupButton.menu?.delegate = self

            let item = CustomValidationToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Open With", comment: ""),
                tooltip: NSLocalizedString("Open using selected application", comment: ""),
                image: NSImage(named: VDImageNameFinder),
                target: nil,
                action: nil
            )
            item.view = popupButton

            return item
        } else if itemIdentifier == .Folders.showInFinder {
            return NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Show in Finder", comment: ""),
                tooltip: NSLocalizedString("Show in Finder", comment: ""),
                image: NSImage(named: VDImageNameFinder),
                target: self,
                action: #selector(showInFinder)
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
        return true
    }

    func updateToolbarButton(_ item: NSToolbarItem) {
        switch lastUsedView.side {
        case .left:
            if item.itemIdentifier == .Folders.copy {
                item.image = NSImage(named: VDImageNameCopyRight)
            } else if item.itemIdentifier == .Folders.sync {
                item.image = NSImage(named: VDImageNameSyncRight)
            } else if item.itemIdentifier == .Folders.move {
                item.image = NSImage(named: VDImageNameMoveRight)
            }
        case .right:
            if item.itemIdentifier == .Folders.copy {
                item.image = NSImage(named: VDImageNameCopyLeft)
            } else if item.itemIdentifier == .Folders.sync {
                item.image = NSImage(named: VDImageNameSyncLeft)
            } else if item.itemIdentifier == .Folders.move {
                item.image = NSImage(named: VDImageNameMoveLeft)
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
}
