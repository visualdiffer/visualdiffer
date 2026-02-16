//
//  FoldersWindowController+Menu.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

// swiftlint:disable file_length
extension FoldersWindowController {
    // swiftlint:disable:next function_body_length
    private static func editMenu() -> NSMenu {
        let menu = NSMenu(title: NSLocalizedString("Edit", comment: ""))

        menu.addItem(
            withTitle: NSLocalizedString("Cut", comment: ""),
            action: #selector(NSText.cut(_:)),
            keyEquivalent: "x"
        )
        menu.addItem(
            withTitle: NSLocalizedString("Copy Paths", comment: ""),
            action: #selector(copy(_:)),
            keyEquivalent: "c"
        )

        let copyFileNames = NSMenuItem(
            title: NSLocalizedString("Copy File Names", comment: ""),
            action: #selector(copyFileNames),
            keyEquivalent: "c"
        )
        copyFileNames.isAlternate = true
        copyFileNames.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(copyFileNames)

        // TODO: copy urls no longer work for some sandbox problem so we disable it entirely
        //        menu.addItem(withTitle: NSLocalizedString("Copy URLs", comment: ""), action:#selector(copyUrls), keyEquivalent:"u")
        menu.addItem(
            withTitle: NSLocalizedString("Paste", comment: ""),
            action: #selector(NSText.paste),
            keyEquivalent: "v"
        )
        menu.addItem(
            withTitle: NSLocalizedString("Delete", comment: ""),
            action: #selector(NSText.delete),
            keyEquivalent: ""
        )

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            withTitle: NSLocalizedString("Select All", comment: ""),
            action: #selector(selectAll),
            keyEquivalent: "a"
        )

        let selectAllBothSides = NSMenuItem(
            title: NSLocalizedString("Select All Both Sides", comment: ""),
            action: #selector(selectAllBothSides),
            keyEquivalent: "a"
        )
        selectAllBothSides.isAlternate = true
        selectAllBothSides.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(selectAllBothSides)

        menu.addItem(
            withTitle: NSLocalizedString("Select All Files", comment: ""),
            action: #selector(selectAllFiles),
            keyEquivalent: "e"
        )

        let selectAllFilesBoth = NSMenuItem(
            title: NSLocalizedString("Select All Files Both Sides", comment: ""),
            action: #selector(selectAllFiles),
            keyEquivalent: "e"
        )
        selectAllFilesBoth.tag = SelectionSide.both.rawValue
        selectAllFilesBoth.isAlternate = true
        selectAllFilesBoth.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(selectAllFilesBoth)

        menu.addItem(
            withTitle: NSLocalizedString("Select All Folders", comment: ""),
            action: #selector(selectAllFolders),
            keyEquivalent: "t"
        )

        let selectAllFoldersBoth = NSMenuItem(
            title: NSLocalizedString("Select All Folders Both Sides", comment: ""),
            action: #selector(selectAllFolders),
            keyEquivalent: "t"
        )
        selectAllFoldersBoth.tag = SelectionSide.both.rawValue
        selectAllFoldersBoth.isAlternate = true
        selectAllFoldersBoth.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(selectAllFoldersBoth)

        // Select Newer submenu
        let selectNewerItem = NSMenuItem(
            title: NSLocalizedString("Select Newer", comment: ""),
            action: nil,
            keyEquivalent: ""
        )
        let selectNewerSub = NSMenu(title: NSLocalizedString("Select Newer", comment: ""))
        selectNewerSub.addItem(
            withTitle: NSLocalizedString("Left Side", comment: ""),
            action: #selector(selectNewer),
            keyEquivalent: "1"
        ).tag = SelectionSide.left.rawValue
        selectNewerSub.addItem(
            withTitle: NSLocalizedString("Right Side", comment: ""),
            action: #selector(selectNewer),
            keyEquivalent: "2"
        ).tag = SelectionSide.right.rawValue
        selectNewerSub.addItem(
            withTitle: NSLocalizedString("Both Sides", comment: ""),
            action: #selector(selectNewer),
            keyEquivalent: "3"
        ).tag = SelectionSide.both.rawValue
        menu.setSubmenu(selectNewerSub, for: selectNewerItem)
        menu.addItem(selectNewerItem)

        // Select Orphans submenu
        let selectOrphansItem = NSMenuItem(
            title: NSLocalizedString("Select Orphans", comment: ""),
            action: nil,
            keyEquivalent: ""
        )
        let selectOrphansSub = NSMenu(title: NSLocalizedString("Select Orphans", comment: ""))
        selectOrphansSub.addItem(
            withTitle: NSLocalizedString("Left Side", comment: ""),
            action: #selector(selectOrphans),
            keyEquivalent: "4"
        ).tag = SelectionSide.left.rawValue
        selectOrphansSub.addItem(
            withTitle: NSLocalizedString("Right Side", comment: ""),
            action: #selector(selectOrphans),
            keyEquivalent: "5"
        ).tag = SelectionSide.right.rawValue
        selectOrphansSub.addItem(
            withTitle: NSLocalizedString("Both Sides", comment: ""),
            action: #selector(selectOrphans),
            keyEquivalent: "6"
        ).tag = SelectionSide.both.rawValue
        menu.setSubmenu(selectOrphansSub, for: selectOrphansItem)
        menu.addItem(selectOrphansItem)

        menu.addItem(
            withTitle: NSLocalizedString("Invert Selection", comment: ""),
            action: #selector(invertSelection),
            keyEquivalent: "i"
        )

        let invertBoth = NSMenuItem(
            title: NSLocalizedString("Invert Selection Both Sides", comment: ""),
            action: #selector(invertSelection),
            keyEquivalent: "i"
        )
        invertBoth.tag = SelectionSide.both.rawValue
        invertBoth.isAlternate = true
        invertBoth.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(invertBoth)

        menu.addItem(NSMenuItem.separator())

        // Find submenu
        let findItem = NSMenuItem(
            title: NSLocalizedString("Find", comment: ""),
            action: nil,
            keyEquivalent: ""
        )
        let findSub = NSMenu(title: NSLocalizedString("Find", comment: ""))
        findSub.addItem(
            withTitle: NSLocalizedString("Find...", comment: ""),
            action: #selector(find),
            keyEquivalent: "f"
        )
        findSub.addItem(
            withTitle: NSLocalizedString("Find Next", comment: ""),
            action: #selector(findNext),
            keyEquivalent: "g"
        )
        findSub.addItem(
            withTitle: NSLocalizedString("Find Previous", comment: ""),
            action: #selector(findPrevious),
            keyEquivalent: "G"
        )
        menu.setSubmenu(findSub, for: findItem)
        menu.addItem(findItem)

        return menu
    }

    private static func actionsMenu() -> NSMenu {
        let menu = NSMenu(title: NSLocalizedString("Actions", comment: ""))

        menu.addItem(
            withTitle: NSLocalizedString("Set as Base Folder", comment: ""),
            action: #selector(setAsBaseFolder),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: NSLocalizedString("Set as Base Folder on the Other Side", comment: ""),
            action: #selector(setAsBaseFolderOtherSide),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: NSLocalizedString("Set as Base Folder Both Sides", comment: ""),
            action: #selector(setAsBaseFoldersBothSides),
            keyEquivalent: ""
        )

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            withTitle: NSLocalizedString("Compare Files", comment: ""),
            action: #selector(compareFiles),
            keyEquivalent: ""
        )
        let copyFilesItem = NSMenuItem(
            title: NSLocalizedString("Copy Files...", comment: ""),
            action: #selector(copyFiles),
            keyEquivalent: KeyEquivalent.f5
        )
        copyFilesItem.keyEquivalentModifierMask = []
        menu.addItem(copyFilesItem)

        let copyFinderMetadata = NSMenuItem(
            title: NSLocalizedString("Copy Metadata...", comment: ""),
            action: #selector(copyFiles),
            keyEquivalent: KeyEquivalent.f5
        )
        copyFinderMetadata.keyEquivalentModifierMask = [.shift]
        copyFinderMetadata.tag = CopyFilesTag.finderMetadataOnly.rawValue
        menu.addItem(copyFinderMetadata)

        let syncFiles = NSMenuItem(
            title: NSLocalizedString("Sync Files...", comment: ""),
            action: #selector(syncFiles),
            keyEquivalent: KeyEquivalent.f6
        )
        syncFiles.keyEquivalentModifierMask = []
        menu.addItem(syncFiles)

        menu.addItem(
            withTitle: NSLocalizedString("Delete Files...", comment: ""),
            action: #selector(deleteFiles),
            keyEquivalent: KeyEquivalent.deleteBackspace
        )
        menu.addItem(
            withTitle: NSLocalizedString("Move Files...", comment: ""),
            action: #selector(moveFiles),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: NSLocalizedString("Set Modification Date...", comment: ""),
            action: #selector(setModificationDate),
            keyEquivalent: ""
        )

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            withTitle: NSLocalizedString("Copy Filenames", comment: ""),
            action: #selector(copyFileNames),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: NSLocalizedString("Show in Finder", comment: ""),
            action: #selector(showInFinder),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: NSLocalizedString("Open With", comment: ""),
            action: #selector(popupOpenWithApp),
            keyEquivalent: ""
        )

        let quickLook = NSMenuItem(
            title: NSLocalizedString("Quick Look", comment: ""),
            action: #selector(togglePreviewPanel),
            keyEquivalent: "y"
        )
        quickLook.image = NSImage(named: NSImage.quickLookTemplateName)
        menu.addItem(quickLook)

        return menu
    }

    private static func viewMenu() -> NSMenu {
        let menu = NSMenu(title: NSLocalizedString("View", comment: ""))

        menu.addItem(
            withTitle: NSLocalizedString("Set Left Read-Only", comment: ""),
            action: #selector(setLeftReadOnly),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: NSLocalizedString("Set Right Read-Only", comment: ""),
            action: #selector(setRightReadOnly),
            keyEquivalent: ""
        )
        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            withTitle: NSLocalizedString("Show Filtered Files", comment: ""),
            action: #selector(toggleFilteredFiles),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: NSLocalizedString("Show Empty Folders", comment: ""),
            action: #selector(showEmptyFolders),
            keyEquivalent: ""
        )

        menu.addItem(
            withTitle: NSLocalizedString("Expand Selected Subfolders", comment: ""),
            action: #selector(expandSelectedSubfolders),
            keyEquivalent: "*"
        )
        let expandAllItem = menu.addItem(
            withTitle: NSLocalizedString("Expand All", comment: ""),
            action: #selector(expandAllFolders),
            keyEquivalent: "+"
        )
        expandAllItem.keyEquivalentModifierMask = .control

        let collapseAllItem = menu.addItem(
            withTitle: NSLocalizedString("Collapse All", comment: ""),
            action: #selector(collapseAllFolders),
            keyEquivalent: "-"
        )
        collapseAllItem.keyEquivalentModifierMask = .control

        menu.addItem(
            withTitle: NSLocalizedString("Swap Sides", comment: ""),
            action: #selector(swapSides),
            keyEquivalent: ""
        )

        menu.addItem(
            withTitle: NSLocalizedString("Refresh", comment: ""),
            action: #selector(refresh),
            keyEquivalent: "r"
        )
        menu.addItem(NSMenuItem.separator())

        // Font submenu
        let fontItem = NSMenuItem(
            title: NSLocalizedString("Font", comment: ""),
            action: nil,
            keyEquivalent: ""
        )
        let fontSub = NSMenu(title: NSLocalizedString("Font", comment: ""))
        fontSub.addItem(
            withTitle: NSLocalizedString("Larger", comment: ""),
            action: #selector(zoomLargerFont),
            keyEquivalent: "+"
        )
        fontSub.addItem(
            withTitle: NSLocalizedString("Smaller", comment: ""),
            action: #selector(zoomSmallerFont),
            keyEquivalent: "-"
        )
        fontSub.addItem(NSMenuItem.separator())
        fontSub.addItem(
            withTitle: NSLocalizedString("Reset", comment: ""),
            action: #selector(zoomResetFont),
            keyEquivalent: "0"
        )
        menu.setSubmenu(fontSub, for: fontItem)
        menu.addItem(fontItem)

        let logConsole = NSMenuItem(
            title: NSLocalizedString("Show Log Console", comment: ""),
            action: #selector(toggleLogConsole),
            keyEquivalent: "l"
        )
        logConsole.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(logConsole)

        let toolbarItem = NSMenuItem(
            title: NSLocalizedString("Show Toolbar", comment: ""),
            action: #selector(NSWindow.toggleToolbarShown(_:)),
            keyEquivalent: "t"
        )
        toolbarItem.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(toolbarItem)

        menu.addItem(
            withTitle: NSLocalizedString("Customize Toolbar…", comment: ""),
            action: #selector(NSWindow.runToolbarCustomizationPalette(_:)),
            keyEquivalent: ""
        )
        return menu
    }

    @objc static func switchMenu() {
        @MainActor enum StaticMenus {
            static let edit = FoldersWindowController.editMenu()
            static let actions = FoldersWindowController.actionsMenu()
            static let view = FoldersWindowController.viewMenu()
        }
        guard let mainMenu = NSApp.mainMenu else {
            return
        }
        mainMenu.item(withTag: MainMenu.edit.rawValue)?.submenu = StaticMenus.edit
        mainMenu.item(withTag: MainMenu.actions.rawValue)?.submenu = StaticMenus.actions
        mainMenu.item(withTag: MainMenu.view.rawValue)?.submenu = StaticMenus.view
    }
}

// swiftlint:enable file_length
