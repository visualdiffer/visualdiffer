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
    var component: DiffLineComponent
    var isSectionSeparator = false
    var filteredIndex = 0

    var text: String {
        component.text
    }

    init(
        with type: DiffChangeType,
        number: Int,
        component: DiffLineComponent
    ) {
        self.type = type
        self.number = number
        self.component = component
    }

    static func missingLine() -> DiffLine {
        DiffLine(
            with: .missing,
            number: invalidLineNumber,
            component: DiffLineComponent(text: "", eol: .missing)
        )
    }

    func makeMissing() {
        type = .missing
        component = DiffLineComponent(text: "", eol: .missing)
        number = Self.invalidLineNumber
    }
}

extension DiffLine: CustomStringConvertible {
    var description: String {
        String(format: "%ld %@ : %@", number, type.description, text)
    }
}
