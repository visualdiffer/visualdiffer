//
//  FolderReader+Log.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/02/25.
//  Copyright (c) 2025 visualdiffer.com
//

import os.log

#if DEBUG
    extension FolderReader {
        // periphery:ignore
        func writelog(_ leftRoot: CompareItem) {
            let home = URL(filePath: NSHomeDirectory())
            let fullPath = home.appendingPathComponent("vd.txt").osPath
            Logger.debug.info("log output to \(fullPath)")

            try? FileManager.default.removeItem(atPath: fullPath)
            var fileHandle = FileHandle(forWritingAtPath: fullPath)

            if fileHandle == nil {
                FileManager.default.createFile(atPath: fullPath, contents: nil, attributes: nil)
                fileHandle = FileHandle(forWritingAtPath: fullPath)
            }
            guard let fileHandle else {
                return
            }
            defer {
                fileHandle.closeFile()
            }

            let des = String(
                format: "flags %@\ntolerance %ld maxReadBytes %ld isLeftCase %d isRightCase %d",
                comparator.options.debugDescription,
                comparator.timestampToleranceSeconds,
                comparator.bufferSize,
                comparator.isLeftCaseSensitive,
                comparator.isRightCaseSensitive
            )

            let config = String(
                format: "showFilteredFiles = %d, hideEmptyFolders = %d, followSymLinks = %d, skipPackages = %d, traverseFilteredFolders = %d",
                filterConfig.showFilteredFiles,
                filterConfig.hideEmptyFolders,
                filterConfig.followSymLinks,
                filterConfig.skipPackages,
                filterConfig.traverseFilteredFolders
            )
            VisibleItem.writeLine(fileHandle, line: config)

            VisibleItem.writeLine(fileHandle, line: des)
            leftRoot.visibleItem?.writelog(fileHandle, indent: 2)
        }
    }
#endif
