//
//  OpenEditorAttribute.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

struct OpenEditorAttribute {
    var path: URL
    var lineNumber: Int
    var columnNumber: Int

    init(path: String, lineNumber: Int = 1, columnNumber: Int = 1) {
        self.init(url: URL(filePath: path), lineNumber: lineNumber, columnNumber: columnNumber)
    }

    init(url: URL, lineNumber: Int = 1, columnNumber: Int = 1) {
        path = url
        self.lineNumber = lineNumber
        self.columnNumber = columnNumber
    }
}

extension OpenEditorAttribute {
    func arguments() -> [String] {
        [
            path.osPath,
            "\(lineNumber)",
            "\(columnNumber)",
        ]
    }
}
