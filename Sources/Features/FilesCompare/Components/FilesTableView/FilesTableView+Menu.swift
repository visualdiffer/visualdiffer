//
//  FilesTableView+Menu.swift
//  VisualDiffer
//
//  Created by davide ficano on 20/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

@objc protocol FilesTableViewContextMenu {
    func copyFileNames(_ sender: AnyObject?)
    func copyFullPaths(_ sender: AnyObject?)
    func copyLines(_ sender: AnyObject?)
    func deleteLines(_ sender: AnyObject?)
    func popupOpenWithApp(_ sender: AnyObject?)
    func saveFile(_ sender: AnyObject?)
    func selectSection(_ sender: AnyObject?)
    func showInFinder(_ sender: AnyObject?)
    func showWhitespaces(_ sender: AnyObject?)
}

extension FilesTableView {
    override class var defaultMenu: NSMenu? {
        let theMenu = NSMenu(title: NSLocalizedString("Contextual Menu", comment: ""))
        theMenu.autoenablesItems = false

        theMenu.addItem(
            withTitle: NSLocalizedString("Show Whitespace", comment: ""),
            action: #selector(FilesTableViewContextMenu.showWhitespaces),
            keyEquivalent: ""
        )
        theMenu.addItem(
            withTitle: NSLocalizedString("Select Section", comment: ""),
            action: #selector(FilesTableViewContextMenu.selectSection),
            keyEquivalent: ""
        )
        theMenu.addItem(NSMenuItem.separator())

        theMenu.addItem(
            withTitle: NSLocalizedString("Copy Lines", comment: ""),
            action: #selector(FilesTableViewContextMenu.copyLines),
            keyEquivalent: ""
        )
        theMenu.addItem(NSMenuItem.separator())
        theMenu.addItem(
            withTitle: NSLocalizedString("Delete Lines", comment: ""),
            action: #selector(FilesTableViewContextMenu.deleteLines),
            keyEquivalent: ""
        )
        theMenu.addItem(NSMenuItem.separator())

        var item: NSMenuItem
        theMenu.addItem(
            withTitle: NSLocalizedString("Copy Path", comment: ""),
            action: #selector(FilesTableViewContextMenu.copyFullPaths),
            keyEquivalent: ""
        )
        item = theMenu.addItem(
            withTitle: NSLocalizedString("Copy File Name", comment: ""),
            action: #selector(FilesTableViewContextMenu.copyFileNames),
            keyEquivalent: ""
        )
        item.keyEquivalentModifierMask = .option
        item.isAlternate = true

        theMenu.addItem(
            withTitle: NSLocalizedString("Show in Finder", comment: ""),
            action: #selector(FilesTableViewContextMenu.showInFinder),
            keyEquivalent: ""
        )
        theMenu.addItem(
            withTitle: NSLocalizedString("Open With", comment: ""),
            action: #selector(FilesTableViewContextMenu.popupOpenWithApp),
            keyEquivalent: ""
        )

        theMenu.addItem(NSMenuItem.separator())
        theMenu.addItem(
            withTitle: NSLocalizedString("Save", comment: ""),
            action: #selector(FilesTableViewContextMenu.saveFile),
            keyEquivalent: ""
        )

        return theMenu
    }

    // taken from http://www.cocoadev.com/index.pl?RightClickSelectInTableView
    // taken from cyberduck-src-3.6.1/3.6.1/source/ch/cyberduck/ui/cocoa/view/CDListView.m
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
