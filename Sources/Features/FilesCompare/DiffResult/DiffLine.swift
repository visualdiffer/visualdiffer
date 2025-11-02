//
//  DiffLine.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

class DiffLine {
    enum Visibility: Int {
        case all
        case matches
        case differences
    }

    enum DisplayMode {
        case normal
        case merged
    }

    static let invalidLineNumber = -1

    var type: DiffChangeType
    var number: Int
    // mode is used by UI to determine how to draw line
    var mode: DisplayMode = .normal
    var text: String
    var isSectionSeparator = false
    var filteredIndex = 0

    init(
        with type: DiffChangeType,
        number: Int,
        text: String
    ) {
        self.type = type
        self.number = number
        self.text = text
    }

    static func missingLine() -> DiffLine {
        DiffLine(
            with: .missing,
            number: invalidLineNumber,
            text: ""
        )
    }

    func makeMissing() {
        type = .missing
        text = ""
        number = Self.invalidLineNumber
    }
}

extension DiffLine: CustomStringConvertible {
    var description: String {
        String(format: "%ld %@ : %@", number, type.description, text)
    }
}
