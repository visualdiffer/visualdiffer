//
//  FoldersOutlineView+Menu.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

@objc protocol FoldersOutlineViewContextMenu: NSObjectProtocol {
    @MainActor func compareFiles(_ sender: AnyObject?)
    @MainActor func compareFolders(_ sender: AnyObject?)
    @MainActor func copyFileNames(_ sender: AnyObject?)
    @MainActor func copyFiles(_ sender: AnyObject?)
    @MainActor func copyFullPaths(_ sender: AnyObject?)
    @MainActor func deleteFiles(_ sender: AnyObject?)
    @MainActor func excludeByExt(_ sender: AnyObject?)
    @MainActor func excludeByName(_ sender: AnyObject?)
    @MainActor func expandSelectedSubfolders(_ sender: AnyObject?)
    @MainActor func moveFiles(_ sender: AnyObject?)
    @MainActor func popupOpenWithApp(_ sender: AnyObject?)
    @MainActor func setAsBaseFolder(_ sender: AnyObject?)
    @MainActor func setAsBaseFolderOtherSide(_ sender: AnyObject?)
    @MainActor func setAsBaseFoldersBothSides(_ sender: AnyObject?)
    @MainActor func showInFinder(_ sender: AnyObject?)
    @MainActor func togglePreviewPanel(_ sender: AnyObject?)
}

public extension FoldersOutlineView {
    // MARK: - Menu Definition

    override class var defaultMenu: NSMenu? {
        let theMenu = NSMenu(title: NSLocalizedString("Contextual Menu", comment: ""))
        theMenu.autoenablesItems = false
        theMenu.addItem(
            withTitle: NSLocalizedString("Expand all Subfolders", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.expandSelectedSubfolders),
            keyEquivalent: ""
        )
        theMenu.addItem(
            withTitle: NSLocalizedString("Set as Base Folder", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.setAsBaseFolder),
            keyEquivalent: ""
        )
        theMenu.addItem(
            withTitle: NSLocalizedString("Set as Base Folder on the Other Side", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.setAsBaseFolderOtherSide),
            keyEquivalent: ""
        )
        theMenu.addItem(
            withTitle: NSLocalizedString("Set as Base Folders Both Sides", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.setAsBaseFoldersBothSides),
            keyEquivalent: ""
        )
        theMenu.addItem(
            withTitle: NSLocalizedString("Compare Files", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.compareFiles),
            keyEquivalent: ""
        )
        theMenu.addItem(
            withTitle: NSLocalizedString("Compare Folders", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.compareFolders),
            keyEquivalent: ""
        )

        theMenu.addItem(
            withTitle: NSLocalizedString("Copy...", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.copyFiles),
            keyEquivalent: ""
        )

        let copyFinderMetadataItem = theMenu.addItem(
            withTitle: NSLocalizedString("Copy Metadata...", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.copyFiles),
            keyEquivalent: ""
        )
        copyFinderMetadataItem.keyEquivalentModifierMask = [.shift]
        copyFinderMetadataItem.tag = CopyFilesTag.finderMetadataOnly.rawValue

        theMenu.addItem(
            withTitle: NSLocalizedString("Delete...", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.deleteFiles),
            keyEquivalent: ""
        )
        theMenu.addItem(
            withTitle: NSLocalizedString("Move...", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.moveFiles),
            keyEquivalent: ""
        )

        theMenu.addItem(NSMenuItem.separator())

        theMenu.addItem(
            withTitle: NSLocalizedString("Exclude Items", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.excludeByName),
            keyEquivalent: ""
        )
        theMenu.addItem(
            withTitle: NSLocalizedString("Exclude by Ext", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.excludeByExt),
            keyEquivalent: ""
        )

        theMenu.addItem(NSMenuItem.separator())

        theMenu.addItem(
            withTitle: NSLocalizedString("Copy Paths", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.copyFullPaths),
            keyEquivalent: ""
        )
        let copyFileNamesItem = theMenu.addItem(
            withTitle: NSLocalizedString("Copy File Names", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.copyFileNames),
            keyEquivalent: ""
        )
        copyFileNamesItem.keyEquivalentModifierMask = .option
        copyFileNamesItem.isAlternate = true

        theMenu.addItem(
            withTitle: NSLocalizedString("Show in Finder", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.showInFinder),
            keyEquivalent: ""
        )
        theMenu.addItem(
            withTitle: NSLocalizedString("Open With", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.popupOpenWithApp),
            keyEquivalent: ""
        )
        let quickLookItem = theMenu.addItem(
            withTitle: NSLocalizedString("Quick Look", comment: ""),
            action: #selector(FoldersOutlineViewContextMenu.togglePreviewPanel),
            keyEquivalent: ""
        )
        quickLookItem.image = NSImage(named: NSImage.quickLookTemplateName)

        return theMenu
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let wherePoint = convert(event.locationInWindow, from: nil)
        let row = row(at: wherePoint)

        // if mouse isn't outside any row simply doesn't show menu
        if row < 0 {
            return nil
        }

        // highlight the view containing the menu
        superview?.window?.makeFirstResponder(superview)

        let indexes = selectedRowIndexes
        if !indexes.contains(row) {
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        let theMenu = Self.defaultMenu

        if let theMenu,
           let delegate = delegate as? TableViewContextMenuDelegate {
            var lastVisibleItem: NSMenuItem?
            var hasVisibleItemBeforeSeparator = false
            var hasVisibleItems = false

            for item in theMenu.items {
                var hide = false

                if item.isSeparatorItem {
                    item.isHidden = !hasVisibleItemBeforeSeparator
                    hasVisibleItemBeforeSeparator = false
                    lastVisibleItem = item
                } else {
                    let isValid = delegate.tableView(self, menuItem: item, hideMenuItem: &hide)
                    if isValid {
                        item.isHidden = false
                        item.isEnabled = true
                    } else {
                        item.isHidden = hide
                        item.isEnabled = false
                    }
                    if !item.isHidden {
                        lastVisibleItem = item
                        hasVisibleItemBeforeSeparator = true
                        hasVisibleItems = true
                    }
                }
            }

            // hide last item if it's a separator
            if let lastVisibleItem,
               lastVisibleItem.isSeparatorItem {
                lastVisibleItem.isHidden = true
            }
            if !hasVisibleItems {
                theMenu.addItem(
                    withTitle: NSLocalizedString("No actions for current selection", comment: ""),
                    action: nil,
                    keyEquivalent: ""
                )
                .isEnabled = false
            }
        }

        return theMenu
    }
}
