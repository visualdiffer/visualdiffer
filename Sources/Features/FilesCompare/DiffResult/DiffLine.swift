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
    var component: DiffLineComponent {
        didSet {
            // the offsets belong to the replaced text, they cannot survive it
            inlineRanges = []
        }
    }

    var isSectionSeparator = false
    var filteredIndex = 0
    var hasIgnoredDifferences: Bool

    // character offsets, relative to component.text, that differ from the paired line,
    // meaningful only when type is .changed
    var inlineRanges = [Range<Int>]()

    var text: String {
        component.text
    }

    init(
        with type: DiffChangeType,
        number: Int,
        component: DiffLineComponent,
        hasIgnoredDifferences: Bool = false
    ) {
        self.type = type
        self.number = number
        self.component = component
        self.hasIgnoredDifferences = hasIgnoredDifferences
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
        hasIgnoredDifferences = false
    }
}

extension DiffLine: CustomStringConvertible {
    var description: String {
        String(format: "%ld %@ : %@", number, type.description, text)
    }
}

/// identity semantics, a line is a mutable reference and two distinct lines stay
/// distinct even while they hold the same text
extension DiffLine: Hashable {
    static func == (lhs: DiffLine, rhs: DiffLine) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
