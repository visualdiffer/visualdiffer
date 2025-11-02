//
//  DiffSection.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

class DiffSection {
    private(set) var start: Int
    private(set) var end: Int

    var range: ClosedRange<Int> {
        start ... end
    }

    init(start: Int = 0, end: Int = 0) {
        self.start = start
        self.end = end
    }

    static func compact(sections: [DiffSection]) -> [DiffSection] {
        var start = 0
        var compacted = [DiffSection]()
        compacted.reserveCapacity(sections.count)

        for section in sections {
            let len = section.end - section.start + 1
            compacted.append(DiffSection(start: start, end: start + section.end - section.start))
            start += len
        }
        return compacted
    }
}

extension DiffSection: CustomStringConvertible {
    var description: String {
        String(format: "(%ld, %ld)", start, end)
    }
}

extension DiffSection: Equatable {
    static func == (lhs: DiffSection, rhs: DiffSection) -> Bool {
        lhs.start == rhs.start && lhs.end == rhs.end
    }
}
