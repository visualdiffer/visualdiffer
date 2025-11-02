//
//  FileAttributes.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

/**
 * This is a wrapper used in async calls, it is Sendable
 */
struct FileAttributes: Sendable {
    var modificationDate: Date?
    var size: Int64?
}

extension [FileAttributeKey: Any] {
    func toFileAttributes() -> FileAttributes? {
        FileAttributes(
            modificationDate: self[.modificationDate] as? Date,
            size: self[.size] as? Int64
        )
    }
}

extension FileAttributes {
    func toFileAttributeKeys() -> [FileAttributeKey: Any] {
        var attrs: [FileAttributeKey: Any] = [:]

        if let modificationDate {
            attrs[.modificationDate] = modificationDate
        }

        if let size {
            attrs[.size] = size
        }

        return attrs
    }
}
