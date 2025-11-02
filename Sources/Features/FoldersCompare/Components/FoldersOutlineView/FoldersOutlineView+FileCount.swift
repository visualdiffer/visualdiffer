//
//  FoldersOutlineView+FileCount.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

struct FileCountInfo {
    let fileCount: Int
    let size: Int64
    let selectionContainsFiles: Bool
}

extension FileCountInfo: CustomStringConvertible {
    var description: String {
        if selectionContainsFiles {
            return String.localizedStringWithFormat(
                NSLocalizedString("Selected %ld files, %@", comment: "Selected 3 files, 4.1GB"),
                fileCount,
                FileSizeFormatter.default.string(from: NSNumber(value: size)) ?? ""
            )
        }
        return String.localizedStringWithFormat(
            NSLocalizedString("%ld files, %@", comment: "3 files, 4.1GB"),
            fileCount,
            FileSizeFormatter.default.string(from: NSNumber(value: size)) ?? ""
        )
    }
}

extension FoldersOutlineView {
    func getFileCountInfo() -> FileCountInfo {
        var fileCount = 0
        var size = Int64(0)

        for row in selectedRowIndexes {
            if let vi = item(atRow: row) as? VisibleItem {
                let item = vi.item

                if item.isValidFile, item.isFile {
                    fileCount += 1
                    size += Int64(item.fileSize)
                }
            }
        }
        let selectionContainsFiles = fileCount != 0

        if !selectionContainsFiles {
            for row in 0 ..< numberOfRows {
                if let vi = item(atRow: row) as? VisibleItem {
                    let item = vi.item

                    if item.isValidFile, item.isFile {
                        fileCount += 1
                        size += Int64(item.fileSize)
                    }
                }
            }
        }
        return FileCountInfo(
            fileCount: fileCount,
            size: size,
            selectionContainsFiles: selectionContainsFiles
        )
    }
}
