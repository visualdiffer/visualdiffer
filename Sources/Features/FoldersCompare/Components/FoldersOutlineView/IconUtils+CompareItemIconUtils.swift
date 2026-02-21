//
//  IconUtils+CompareItemIconUtils.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/11/14.
//  Copyright (c) 2014 visualdiffer.com
//

@MainActor
extension IconUtils {
    func icon(
        for item: CompareItem,
        size: CGFloat,
        isExpanded: Bool,
        hideEmptyFolders: Bool
    ) -> NSImage? {
        var icon: NSImage?

        if item.isValidFile,
           let url = item.toUrl() {
            if item.isLocked {
                if item.isFolder {
                    let name = ColoredFoldersManager.shared.iconName(
                        item,
                        isExpanded: isExpanded,
                        hideEmptyFolders: hideEmptyFolders
                    )
                    let url = URL(filePath: name)
                    icon = self.icon(forLockedFile: url, size: size)
                } else {
                    icon = self.icon(forLockedFile: url, size: size)
                }
            } else if item.isSymbolicLink {
                if item.isFolder {
                    let name = ColoredFoldersManager.shared.iconName(
                        item,
                        isExpanded: isExpanded,
                        hideEmptyFolders: hideEmptyFolders
                    )
                    let url = URL(filePath: name)
                    icon = self.icon(forSymbolicLink: url, size: size)
                } else {
                    icon = self.icon(forSymbolicLink: url, size: size)
                }
            } else {
                if item.isFolder {
                    icon = ColoredFoldersManager.shared.icon(
                        forFolder: item,
                        size: size,
                        isExpanded: isExpanded,
                        hideEmptyFolders: hideEmptyFolders
                    )
                } else {
                    // get the icon from path because for some files (eg resource forks)
                    // the file type should be irrelevant
                    // This means caching every single path
                    icon = self.icon(forFile: url, size: size)
                }
            }
        }
        return icon
    }
}
