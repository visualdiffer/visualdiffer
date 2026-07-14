//
//  IconUtils+CompareItemIconUtils.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/11/14.
//  Copyright (c) 2014 visualdiffer.com
//

import os.log

@MainActor
extension IconUtils {
    func icon(
        for item: CompareItem,
        size: CGFloat,
        isExpanded: Bool,
        hideEmptyFolders: Bool
    ) -> NSImage? {
        guard item.isValidFile,
              let url = item.toURL() else {
            return nil
        }

        let (name, baseIcon) = if item.isFolder {
            coloredFolder(
                for: item,
                isExpanded: isExpanded,
                hideEmptyFolders: hideEmptyFolders
            )
        } else {
            // get the icon from path because for some files (eg resource forks)
            // the file type should be irrelevant
            // This means caching every single path
            (url.osPath, icon(forFile: url, size: size))
        }

        guard let baseIcon else {
            Logger.ui.error("Unable to find icon for \(name, privacy: .public)")
            return nil
        }
        guard let badgeImage = badgeImage(for: item, size: size) else {
            return baseIcon
        }

        return badge(forName: name, source: baseIcon, icon: badgeImage, size: size)
    }

    private func badgeImage(for item: CompareItem, size: CGFloat) -> NSImage? {
        if item.isLocked {
            lockedBadge(size: size)
        } else if item.isSymbolicLink {
            symbolicLinkBadge(size: size)
        } else {
            nil
        }
    }

    private func coloredFolder(
        for item: CompareItem,
        isExpanded: Bool,
        hideEmptyFolders: Bool
    ) -> (name: String, folderIcon: NSImage?) {
        let name = ColoredFoldersManager.shared.iconName(
            item,
            isExpanded: isExpanded,
            hideEmptyFolders: hideEmptyFolders
        )
        return (name, ColoredFoldersManager.shared.icon(folderName: name))
    }
}
