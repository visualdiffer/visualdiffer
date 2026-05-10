//
//  CopyFilesTag.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/02/26.
//  Copyright (c) 2026 visualdiffer.com
//

enum CopyFilesTag: Int {
    case fileContents = 0
    case finderMetadataOnly = 1

    static func localizedTag(side: DisplaySide, tag: Int) -> String {
        switch side {
        case .left:
            if tag == finderMetadataOnly.rawValue {
                NSLocalizedString("Copy Metadata to Right...", comment: "")
            } else {
                NSLocalizedString("Copy to Right...", comment: "")
            }
        case .right:
            if tag == finderMetadataOnly.rawValue {
                NSLocalizedString("Copy Metadata to Left...", comment: "")
            } else {
                NSLocalizedString("Copy to Left...", comment: "")
            }
        }
    }

    @MainActor
    static func isCopyFinderMetadataOnly(sender: AnyObject?) -> Bool {
        let tag = if let menuItem = sender as? NSMenuItem {
            CopyFilesTag(rawValue: menuItem.tag)
        } else if let toolbarItem = sender as? NSToolbarItem {
            // Press the Shift key when click on toolbar icon to simulate finderMetadataOnly
            if let currentEvent = NSApp.currentEvent,
               currentEvent.modifierFlags.contains(.shift),
               toolbarItem.tag == fileContents.rawValue {
                finderMetadataOnly
            } else {
                CopyFilesTag(rawValue: toolbarItem.tag)
            }
        } else {
            fileContents
        }

        return tag == finderMetadataOnly
    }
}
