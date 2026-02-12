//
//  CompareItem+NSTableCellView.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/06/20.
//  Copyright (c) 2020 visualdiffer.com
//

extension NSUserInterfaceItemIdentifier.Folders {
    static let cellName = NSUserInterfaceItemIdentifier("cellName")
    static let cellSize = NSUserInterfaceItemIdentifier("cellSize")
    static let cellModified = NSUserInterfaceItemIdentifier("cellModified")
}

extension CompareItem {
    func compareChangeType(
        _ cellIdentifier: NSUserInterfaceItemIdentifier?,
        followSymLinks: Bool
    ) -> CompareChangeType {
        if !isValidFile {
            return .unknown
        }

        var type = CompareChangeType.unknown

        if isFiltered {
            type = .filtered
        } else if isFile {
            if isNewerThanLinked {
                type = .newer
            } else if summary.hasMetadataTags || mismatchingTags > 0 {
                type = .mismatchingTags
            } else if summary.hasMetadataLabels || mismatchingLabels > 0 {
                type = .mismatchingLabels
            } else {
                type = self.type
            }
        } else if isFolder {
            if cellIdentifier == .Folders.cellSize {
                type = .subFoldersSize
            } else {
                if isSymbolicLink, !followSymLinks {
                    type = (linkedItem?.isValidFile ?? false) ? .same : .orphan
                } else {
                    if summary.hasMetadataTags {
                        type = .mismatchingTags
                    } else if summary.hasMetadataLabels {
                        type = .mismatchingLabels
                    } else {
                        type = .folder
                    }
                }
            }
        }

        return type
    }
}
