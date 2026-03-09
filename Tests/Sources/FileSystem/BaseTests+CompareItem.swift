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
            attrs: [.type: FileAttributeType.typeDirectory],
            fileExtraOptions: [],
            parent: parent
        )
    }

    func file(_ path: String, parent: CompareItem?) -> CompareItem {
        CompareItem(
            path: path,
            attrs: [.type: FileAttributeType.typeRegular],
            fileExtraOptions: [],
            parent: parent
        )
    }
}
