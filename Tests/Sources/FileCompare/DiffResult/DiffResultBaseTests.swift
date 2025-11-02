//
//  DiffResultBaseTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

class DiffResultBaseTests: BaseTests {
    func assert(
        sectionSeparators lines: [DiffLine],
        separatorIndexes: [Int],
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for (index, line) in lines.enumerated() {
            #expect(line.isSectionSeparator == separatorIndexes.contains(index), sourceLocation: sourceLocation)
        }
    }

    func assert(
        sectionSeparators lines: [DiffLine],
        isSeparator: Bool,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for line in lines {
            #expect(line.isSectionSeparator == isSeparator, sourceLocation: sourceLocation)
        }
    }

    func assert(
        lines: [DiffLine],
        expectedValue: [DiffChangeType],
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(lines.count == expectedValue.count, sourceLocation: sourceLocation)

        for (index, line) in lines.enumerated() {
            #expect(line.type == expectedValue[index], sourceLocation: sourceLocation)
        }
    }

    func assert(
        linesMode lines: [DiffLine],
        modes: [DiffLine.DisplayMode],
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(lines.count == modes.count, sourceLocation: sourceLocation)

        for (index, line) in lines.enumerated() {
            #expect(line.mode == modes[index], sourceLocation: sourceLocation)
        }
    }
}
