//
//  SessionDiff.ItemType+Paths.swift
//  VisualDiffer
//
//  Created by davide ficano on 03/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension SessionDiff.ItemType {
    /**
     * Throw error if paths aren't both of same type (both folders or both files) or don't exist
     */
    func checkPaths(leftPath: String, rightPath: String) throws {
        switch self {
        case .folder:
            try checkFolders(leftPath: leftPath, rightPath: rightPath)
        case .file:
            try checkFiles(leftPath: leftPath, rightPath: rightPath)
        }
    }

    func checkFolders(leftPath: String, rightPath: String) throws {
        let fileManager = FileManager.default
        var isDir = ObjCBool(false)

        // show error only for last invalid path
        if !fileManager.fileExists(atPath: leftPath, isDirectory: &isDir) || !isDir.boolValue {
            throw SessionTypeError.invalidItem(isDir: true, leftExists: false, rightExists: true)
        }

        if !fileManager.fileExists(atPath: rightPath, isDirectory: &isDir) || !isDir.boolValue {
            throw SessionTypeError.invalidItem(isDir: true, leftExists: true, rightExists: false)
        }
    }

    func checkFiles(leftPath: String, rightPath: String) throws {
        let fileManager = FileManager.default

        if leftPath.isEmpty, rightPath.isEmpty {
            throw SessionTypeError.invalidAllItems(isDir: false)
        }
        if !leftPath.isEmpty, !fileManager.fileExists(atPath: leftPath) {
            throw SessionTypeError.invalidItem(isDir: false, leftExists: false, rightExists: true)
        }
        if !rightPath.isEmpty, !fileManager.fileExists(atPath: rightPath) {
            throw SessionTypeError.invalidItem(isDir: false, leftExists: true, rightExists: false)
        }
    }
}
