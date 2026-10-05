//
//  BaseTests+CompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

public extension BaseTests {
    func folder(_ path: String, parent: CompareItem?) -> CompareItem {
        CompareItem(
            path: path,
            attributes: ResolvedFileAttributes(rawAttributes: [.type: FileAttributeType.typeDirectory]),
            parent: parent
        )
    }

    func file(_ path: String, parent: CompareItem?) -> CompareItem {
        CompareItem(
            path: path,
            attributes: ResolvedFileAttributes(rawAttributes: [.type: FileAttributeType.typeRegular]),
            parent: parent
        )
    }
}

extension ResolvedFileAttributes {
    init(rawAttributes: [FileAttributeKey: Any]) {
        let isFolder = rawAttributes.fileAttributeType == .typeDirectory
        self.init(
            rawAttributes: rawAttributes,
            flags: [.isValidFile, isFolder ? .isFolder : .isFile],
            fileSize: rawAttributes[.size] as? Int64 ?? 0,
            modificationDate: rawAttributes[.modificationDate] as? Date
        )
    }
}
