//
//  FoldersWindowController+PathControlDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

let pathControlMenu = 0x1000

extension FoldersWindowController: PathControlDelegate {
    func pathControl(_ pathControl: PathControl, willContextMenu menu: NSMenu) {
        // if the click is outside any cell do not add menus
        if pathControl.clickedPathItem == nil {
            return
        }
        menu.addItem(NSMenuItem.separator())
        // set tag to pathControlMenu otherwise will be used the selected item on view
        menu.addItem(
            withTitle: NSLocalizedString("Set as Base Folder", comment: ""),
            action: #selector(setAsBaseFolder),
            keyEquivalent: ""
        ).tag = pathControlMenu
        menu.addItem(
            withTitle: NSLocalizedString("Set as Base Folder on the Other Side", comment: ""),
            action: #selector(setAsBaseFolderOtherSide),
            keyEquivalent: ""
        ).tag = pathControlMenu
    }

    func pathControl(_: PathControl, chosenUrl _: URL) {
        // no need to check witch path is changed (left or right) because
        // the binding value has already set sessionDiff.<left|right>Path
        reloadAll(RefreshInfo(
            initState: true,
            expandAllFolders: sessionDiff.expandAllFolders
        ))

        synchronizeWindowTitleWithDocumentName()
    }

    public func pathControl(_: NSPathControl, willDisplay openPanel: NSOpenPanel) {
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
    }

    @objc func isPathControlMenu(_ tag: Int) -> Bool {
        (tag & pathControlMenu) == pathControlMenu
    }
}
