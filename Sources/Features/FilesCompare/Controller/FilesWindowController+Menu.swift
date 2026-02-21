//
//  FilesWindowController+Menu.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController {
    private static func editMenu() -> NSMenu {
        let editMenu = NSMenu(title: NSLocalizedString("Edit", comment: ""))

        editMenu.addItem(
            withTitle: NSLocalizedString("Cut", comment: ""),
            action: #selector(cut(_:)),
            keyEquivalent: "x"
        )
        // tells Swift to use "copy:" method that takes a parameter
        // otherwise silently crashes without working for copy lines or copy text selected in NSTextView
        editMenu.addItem(
            withTitle: NSLocalizedString("Copy", comment: ""),
            action: #selector(copy(_:)),
            keyEquivalent: "c"
        )
        // TODO: copy urls no longer work for some sandbox problem so we disable it entirely
//        editMenu.addItem(withTitle: NSLocalizedString("Copy URLs", comment: ""), action: #selector(copyUrlsToClipboard),keyEquivalent: "u")
        editMenu.addItem(
            withTitle: NSLocalizedString("Paste", comment: ""),
            action: #selector(paste(_:)),
            keyEquivalent: "v"
        )

        let deleteItem = NSMenuItem(
            title: NSLocalizedString("Delete", comment: ""),
            action: #selector(deleteLines),
            keyEquivalent: ""
        )
        editMenu.addItem(deleteItem)

        editMenu.addItem(NSMenuItem.separator())

        editMenu.addItem(
            withTitle: NSLocalizedString("Select All", comment: ""),
            action: #selector(selectAll),
            keyEquivalent: "a"
        )
        editMenu.addItem(
            withTitle: NSLocalizedString("Select Section", comment: ""),
            action: #selector(selectSection),
            keyEquivalent: "d"
        )

        let selectAdjacent = NSMenuItem(
            title: NSLocalizedString("Select Adjacent Sections", comment: ""),
            action: #selector(selectAdjacentSections),
            keyEquivalent: "D"
        )
        selectAdjacent.isAlternate = true
        editMenu.addItem(selectAdjacent)

        editMenu.addItem(NSMenuItem.separator())

        let findItem = NSMenuItem(
            title: NSLocalizedString("Find", comment: ""),
            action: nil,
            keyEquivalent: ""
        )
        let findSubmenu = NSMenu(title: NSLocalizedString("Find", comment: ""))
        findSubmenu.addItem(
            withTitle: NSLocalizedString("Find...", comment: ""),
            action: #selector(find),
            keyEquivalent: "f"
        )
        findSubmenu.addItem(
            withTitle: NSLocalizedString("Find Next", comment: ""),
            action: #selector(findNext),
            keyEquivalent: "g"
        )
        findSubmenu.addItem(
            withTitle: NSLocalizedString("Find Previous", comment: ""),
            action: #selector(findPrevious),
            keyEquivalent: "G"
        )
        editMenu.setSubmenu(findSubmenu, for: findItem)
        editMenu.addItem(findItem)

        return editMenu
    }

    private static func actionsMenu() -> NSMenu {
        let actionsMenu = NSMenu(title: NSLocalizedString("Actions", comment: ""))

        let left = NSMenuItem(
            title: NSLocalizedString("Copy Lines to Left", comment: ""),
            action: #selector(copyLinesToLeft),
            keyEquivalent: KeyEquivalent.leftArrow
        )
        left.keyEquivalentModifierMask = [.control, .command]
        left.tag = 1
        actionsMenu.addItem(left)

        let right = NSMenuItem(
            title: NSLocalizedString("Copy Lines to Right", comment: ""),
            action: #selector(copyLinesToRight),
            keyEquivalent: KeyEquivalent.rightArrow
        )
        right.keyEquivalentModifierMask = [.control, .command]
        right.tag = 2
        actionsMenu.addItem(right)

        let deleteLines = NSMenuItem(
            title: NSLocalizedString("Delete Lines", comment: ""),
            action: #selector(deleteLines),
            keyEquivalent: KeyEquivalent.deleteBackspace
        )
        actionsMenu.addItem(deleteLines)

        actionsMenu.addItem(NSMenuItem.separator())

        actionsMenu.addItem(
            withTitle: NSLocalizedString("Copy Filenames", comment: ""),
            action: #selector(copyFileNames),
            keyEquivalent: ""
        )
        actionsMenu.addItem(
            withTitle: NSLocalizedString("Show in Finder", comment: ""),
            action: #selector(showInFinder),
            keyEquivalent: ""
        )
        actionsMenu.addItem(
            withTitle: NSLocalizedString("Open With", comment: ""),
            action: #selector(popupOpenWithApp),
            keyEquivalent: ""
        )

        return actionsMenu
    }

    private static func viewMenu() -> NSMenu {
        let viewMenu = NSMenu(title: NSLocalizedString("View", comment: ""))

        viewMenu.addItem(
            withTitle: NSLocalizedString("Set Left Read-Only", comment: ""),
            action: #selector(setLeftReadOnly),
            keyEquivalent: ""
        )
        viewMenu.addItem(
            withTitle: NSLocalizedString("Set Right Read-Only", comment: ""),
            action: #selector(setRightReadOnly),
            keyEquivalent: ""
        )
        viewMenu.addItem(NSMenuItem.separator())

        viewMenu.addItem(
            withTitle: NSLocalizedString("Swap Sides", comment: ""),
            action: #selector(swapSides),
            keyEquivalent: ""
        )
        viewMenu.addItem(
            withTitle: NSLocalizedString("Word Wrap", comment: ""),
            action: #selector(toggleWordWrap),
            keyEquivalent: "W"
        )
        viewMenu.addItem(
            withTitle: NSLocalizedString("Reload Files", comment: ""),
            action: #selector(reload),
            keyEquivalent: "r"
        )
        viewMenu.addItem(
            withTitle: NSLocalizedString("Recompare", comment: ""),
            action: #selector(recompare),
            keyEquivalent: "R"
        )
        viewMenu.addItem(NSMenuItem.separator())

        let fontItem = NSMenuItem(
            title: NSLocalizedString("Font", comment: ""),
            action: nil,
            keyEquivalent: ""
        )
        let fontMenu = NSMenu(title: NSLocalizedString("Font", comment: ""))
        fontMenu.addItem(
            withTitle: NSLocalizedString("Larger", comment: ""),
            action: #selector(zoomLargerFont),
            keyEquivalent: "+"
        )
        fontMenu.addItem(
            withTitle: NSLocalizedString("Smaller", comment: ""),
            action: #selector(zoomSmallerFont),
            keyEquivalent: "-"
        )
        fontMenu.addItem(NSMenuItem.separator())
        fontMenu.addItem(
            withTitle: NSLocalizedString("Reset", comment: ""),
            action: #selector(zoomResetFont),
            keyEquivalent: "0"
        )
        viewMenu.setSubmenu(fontMenu, for: fontItem)
        viewMenu.addItem(fontItem)

        viewMenu.addItem(
            withTitle: NSLocalizedString("Show Details", comment: ""),
            action: #selector(toggleDetails),
            keyEquivalent: ""
        )

        let toolbarItem = NSMenuItem(
            title: NSLocalizedString("Show Toolbar", comment: ""),
            action: #selector(NSWindow.toggleToolbarShown),
            keyEquivalent: "t"
        )
        toolbarItem.keyEquivalentModifierMask = [.option, .command]
        viewMenu.addItem(toolbarItem)

        viewMenu.addItem(
            withTitle: NSLocalizedString("Customize Toolbar…", comment: ""),
            action: #selector(NSWindow.runToolbarCustomizationPalette),
            keyEquivalent: ""
        )

        return viewMenu
    }

    static func switchMenu() {
        @MainActor
        enum StaticMenus {
            static let edit = FilesWindowController.editMenu()
            static let actions = FilesWindowController.actionsMenu()
            static let view = FilesWindowController.viewMenu()
        }
        guard let mainMenu = NSApp.mainMenu else {
            return
        }
        mainMenu.item(withTag: MainMenu.edit.rawValue)?.submenu = StaticMenus.edit
        mainMenu.item(withTag: MainMenu.actions.rawValue)?.submenu = StaticMenus.actions
        mainMenu.item(withTag: MainMenu.view.rawValue)?.submenu = StaticMenus.view
    }
}
