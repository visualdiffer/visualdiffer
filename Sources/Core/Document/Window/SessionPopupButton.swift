//
//  SessionPopupButton.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/03/26.
//  Copyright (c) 2026 visualdiffer.com
//

@MainActor
class SessionPopupButton: NSPopUpButton {
    convenience init() {
        self.init(
            identifier: .init("sessionMenu"),
            menuTitle: NSLocalizedString("Session", comment: ""),
            menuImage: nil
        )

        title = NSLocalizedString("Session…", comment: "")
        imagePosition = .noImage

        if let menu {
            let blankFileItem = NSMenuItem(
                title: NSLocalizedString("Blank File Compare…", comment: ""),
                action: #selector(openBlankFileCompare),
                keyEquivalent: "b"
            )
            blankFileItem.target = self

            let blankFolderItem = NSMenuItem(
                title: NSLocalizedString("Blank Folder Compare…", comment: ""),
                action: #selector(openBlankFolderCompare),
                keyEquivalent: "b"
            )
            blankFolderItem.target = self
            blankFolderItem.keyEquivalentModifierMask = [.command, .control]

            menu.addItem(blankFileItem)
            menu.addItem(blankFolderItem)
        }
    }

    func insertMenuItem(_ item: NSMenuItem, at index: Int) {
        menu?.insertItem(item, at: index)
    }

    @objc
    func openBlankFileCompare(_ sender: AnyObject?) {
        VDDocumentController.shared.openBlankFileCompare(sender)
    }

    @objc
    func openBlankFolderCompare(_ sender: AnyObject?) {
        VDDocumentController.shared.openBlankFolderCompare(sender)
    }
}
