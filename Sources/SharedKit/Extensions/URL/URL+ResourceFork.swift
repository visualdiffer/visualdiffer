//
//  URL+ResourceFork.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/24.
//  Copyright (c) 2024 visualdiffer.com
//

import Foundation

public extension URL {
    /**
     * Return resource fork sizes
     * @param rsrcPhysicalSize - the physical size of the resource fork
     * @param dataPhysicalSize - the physical size of the data fork
     * @param rsrcLogicalSize - the logical size of the resource fork
     * @param dataLogicalSize - the logical size of the data fork
     */
    func resourceForkForPath(
        _ rsrcPhysicalSize: inout Int,
        _ dataPhysicalSize: inout Int,
        _ rsrcLogicalSize: inout Int,
        _ dataLogicalSize: inout Int
    ) throws {
        let keys: Set<URLResourceKey> = [
            .fileSizeKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey,
            .totalFileSizeKey,
        ]

        let values = try resourceValues(forKeys: keys)
        let fileAllocatedSize = values.fileAllocatedSize ?? 0
        let totalFileAllocatedSize = values.totalFileAllocatedSize ?? 0
        let fileSize = values.fileSize ?? 0
        let totalFileSize = values.totalFileSize ?? 0

        // FSGetCatalogInfo is deprecated so we us NSURL and compute the values manually
        rsrcPhysicalSize = totalFileAllocatedSize - fileAllocatedSize
        dataPhysicalSize = fileAllocatedSize
        rsrcLogicalSize = totalFileSize - fileSize
        dataLogicalSize = fileSize
    }

    /**
     * Return the physical file size
     */
    func resourceForkSize() throws -> Int {
        var rsrcPhysicalSize = 0
        var dataPhysicalSize = 0
        var rsrcLogicalSize = 0
        var dataLogicalSize = 0

        try resourceForkForPath(
            &rsrcPhysicalSize,
            &dataPhysicalSize,
            &rsrcLogicalSize,
            &dataLogicalSize
        )
        return dataLogicalSize + rsrcLogicalSize
    }

    func volumeSupportsCaseSensitive() throws -> Bool {
        let values = try resourceValues(forKeys: [.volumeSupportsCaseSensitiveNamesKey])
        return values.volumeSupportsCaseSensitiveNames ?? false
    }

    func readResFork() throws -> Data {
        let resForkPath = appending(path: "/..namedfork/rsrc")
        let fileHandle = try FileHandle(forReadingFrom: resForkPath)
        defer {
            fileHandle.closeFile()
        }
        return fileHandle.readDataToEndOfFile()
    }
}
