//
//  BaseTests+FileSystemOperations.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

public extension BaseTests {
    func appendFolder(_ path: String, _ isFolder: Bool = true, functionName: String = #function) -> URL {
        rootDir
            .appending(path: functionName.trimmingCharacters(in: CharacterSet(charactersIn: "()")), directoryHint: .isDirectory)
            .appending(path: path, directoryHint: isFolder ? .isDirectory : .notDirectory)
    }

    internal func createFolder(_ path: String, functionName: String = #function) throws {
        try fm.createDirectory(
            at: appendFolder(path, functionName: functionName),
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    internal func createFile(_ path: String, _ content: String, functionName: String = #function) throws {
        try content.write(
            to: appendFolder(path, functionName: functionName),
            atomically: true,
            encoding: .utf8
        )
    }

    internal func removeItem(_ path: String, ignoreError: Bool = true, functionName: String = #function) throws {
        if ignoreError {
            try? fm.removeItem(at: appendFolder(path, functionName: functionName))
        } else {
            try fm.removeItem(at: appendFolder(path, functionName: functionName))
        }
    }

    func setFileTimestamp(_ path: String, _ dateString: String, isFolder: Bool = true, functionName: String = #function) throws {
        try fm.setAttributes(
            [.modificationDate: dateBuilder.isoDate(dateString)],
            ofItemAtPath: appendFolder(path, isFolder, functionName: functionName).osPath
        )
    }

    func createDataFile(_ path: String, _ bytes: [UInt8], functionName: String = #function) throws {
        try Data(bytes: bytes, count: bytes.count).write(to: appendFolder(path, functionName: functionName))
    }

    func setFileCreationTime(_ path: String, _ dateString: String, isFolder: Bool = true, functionName: String = #function) throws {
        try fm.setAttributes(
            [.creationDate: dateBuilder.isoDate(dateString)],
            ofItemAtPath: appendFolder(path, isFolder, functionName: functionName).osPath
        )
    }

    func createSymlink(_ path: String, _ destPath: String, functionName: String = #function) throws {
        try fm.createSymbolicLink(
            at: appendFolder(path, functionName: functionName),
            withDestinationURL: appendFolder(destPath, functionName: functionName)
        )
    }

    func add(
        tags: [String],
        fullPath url: URL
    ) throws {
        // Apple removed from Swift the ability to change tags/labels
        // The workaround consists to continue to use the legacy NSURL
        // https://developer.apple.com/forums/thread/703028
        try (url as NSURL).setResourceValue(tags, forKey: .tagNamesKey)
    }

    func add(
        labelNumber: Int,
        fullPath url: URL
    ) throws {
        // Apple removed from Swift the ability to change tags/labels
        // The workaround consists to continue to use the legacy NSURL
        // https://developer.apple.com/forums/thread/703028
        try (url as NSURL).setResourceValue(NSNumber(value: labelNumber), forKey: .labelNumberKey)
    }

    func getLabelNumber(_ url: URL) throws -> Int {
        let resources = try url.resourceValues(forKeys: [.labelNumberKey])
        if let labelNumber = resources.labelNumber {
            return labelNumber
        }
        return 0
    }
}
