//
//  DiffResultTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length
final class DiffResultTests: DiffResultBaseTests {
    @Test func diffLine() throws {
        let leftText = "line1\n\nline2\nline3"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 1, changed: 1))

        assertArrayCount(diffResult.sections, 2)
        #expect(diffResult.sections[0] == DiffSection(start: 1, end: 1))
        #expect(diffResult.sections[1] == DiffSection(start: 3, end: 3))
    }

    @Test func findNextSection() throws {
        let leftText = "line1\n\nline2\nline3"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        var didWrap = false
        // first move
        if let section = diffResult.findNextSection(by: -1, wrapAround: true, didWrap: &didWrap) {
            #expect(section === diffResult.sections[0])
            #expect(didWrap == false)
        } else {
            Issue.record("No section found")
        }

        // second move
        if let section = diffResult.findNextSection(by: 2, wrapAround: true, didWrap: &didWrap) {
            #expect(section === diffResult.sections[1])
            #expect(didWrap == false)
        } else {
            Issue.record("No section found")
        }

        // third move
        if let section = diffResult.findNextSection(by: 3, wrapAround: true, didWrap: &didWrap) {
            #expect(section === diffResult.sections[0])
            #expect(didWrap == true)
        } else {
            Issue.record("No section found")
        }
    }

    @Test func findPrevSection() throws {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 5, changed: 1))

        var didWrap = false
        // first move
        if let section = diffResult.findPrevSection(by: 5, wrapAround: true, didWrap: &didWrap) {
            #expect(section === diffResult.sections[1])
            #expect(didWrap == false)
        } else {
            Issue.record("No section found")
        }

        // second move
        if let section = diffResult.findPrevSection(by: 3, wrapAround: true, didWrap: &didWrap) {
            #expect(section === diffResult.sections[0])
            #expect(didWrap == false)
        } else {
            Issue.record("No section found")
        }

        // third move
        if let section = diffResult.findPrevSection(by: 1, wrapAround: true, didWrap: &didWrap) {
            #expect(section === diffResult.sections[2])
            #expect(didWrap == true)
        } else {
            Issue.record("No section found")
        }
    }

    @Test func findSectionRange() throws {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        guard let indexes = diffResult.findSectionIndexSet(with: 6) else {
            Issue.record("No indexes found")
            return
        }
        #expect(indexes == IndexSet(integersIn: 4 ..< 8))
    }

    @Test func findAdjacentSections() throws {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 5, changed: 1))

        guard let indexes = diffResult.findAdjacentSections(from: 5) else {
            Issue.record("No indexes found")
            return
        }

        #expect(indexes == IndexSet(integersIn: 3 ..< 8))
    }

    @Test func jumpToLine() {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.leftSide.findLineIndex(by: 5) == 4)
        #expect(diffResult.rightSide.findLineIndex(by: 5) == nil)
    }

    @Test func justDifferentLines() {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        let filtered = DiffResult.justDifferentLines(diffResult)

        #expect(filtered.summary == DiffSummary())

        assertArrayCount(filtered.leftSide.lines, 6)
        assertArrayCount(filtered.rightSide.lines, 6)

        assert(sectionSeparators: filtered.leftSide.lines, separatorIndexes: [0, 1, 5])
        assert(sectionSeparators: filtered.rightSide.lines, separatorIndexes: [0, 1])

        assertArrayCount(filtered.sections, 3)
        #expect(filtered.sections[0] == DiffSection(start: 0, end: 0))
        #expect(filtered.sections[1] == DiffSection(start: 1, end: 1))
        #expect(filtered.sections[2] == DiffSection(start: 2, end: 5))
    }

    @Test func justMatchingLines() {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        let filtered = DiffResult.justMatchingLines(diffResult)

        #expect(filtered.summary == DiffSummary())

        assertArrayCount(filtered.leftSide.lines, 2)
        assertArrayCount(filtered.rightSide.lines, 2)

        assert(sectionSeparators: filtered.leftSide.lines, separatorIndexes: [0, 1])
        assert(sectionSeparators: filtered.rightSide.lines, separatorIndexes: [0, 1])
    }

    @Test func copyLines() {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 5, changed: 1))

        let rowsToCopy = IndexSet([3, 6])

        DiffResult.copyLines(
            all: diffResult,
            current: diffResult,
            rows: rowsToCopy,
            source: .left,
            visibility: .all
        )

        let leftChangeTypeCopied: [DiffChangeType] = [.matching, .deleted, .matching, .matching, .deleted, .deleted, .matching, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeTypeCopied)
        let rightChangeTypeCopied: [DiffChangeType] = [.matching, .missing, .matching, .matching, .missing, .missing, .matching, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeTypeCopied)

        let copiedModes: [DiffLine.DisplayMode] = [.normal, .normal, .normal, .merged, .normal, .normal, .merged, .normal]
        assert(linesMode: diffResult.rightSide.lines, modes: copiedModes)

        let linesStatus = diffResult.rightSide.lines
        let lineNumbers = [1, -1, 2, 3, -1, -1, 4, -1]

        for (index, line) in linesStatus.enumerated() {
            #expect(line.number == lineNumbers[index])
        }
    }

    @Test func copyLinesDifferences() {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 5, changed: 1))

        let rowsToCopy = IndexSet([1, 4])

        let filteredDiffResult = DiffResult.justDifferentLines(diffResult)

        DiffResult.copyLines(
            all: diffResult,
            current: filteredDiffResult,
            rows: rowsToCopy,
            source: .right,
            visibility: .differences
        )

        let leftChangeTypeCopied: [DiffChangeType] = [.deleted, .deleted, .deleted, .deleted]
        assert(lines: filteredDiffResult.leftSide.lines, expectedValue: leftChangeTypeCopied)
        let rightChangeTypeCopied: [DiffChangeType] = [.missing, .missing, .missing, .missing]
        assert(lines: filteredDiffResult.rightSide.lines, expectedValue: rightChangeTypeCopied)

        let copiedMode: [DiffLine.DisplayMode] = Array(repeating: .normal, count: 7)
        assert(linesMode: diffResult.rightSide.lines, modes: copiedMode)

        let linesStatus = filteredDiffResult.leftSide.lines
        let lineNumbers = [2, 5, 6, 7]

        for (index, line) in linesStatus.enumerated() {
            #expect(line.number == lineNumbers[index])
        }
    }

    @Test func deleteLines() {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 5, changed: 1))

        let rowsToDelete = IndexSet([3, 5, 6, 7])

        DiffResult.deleteLines(
            all: diffResult,
            current: diffResult,
            rows: rowsToDelete,
            side: .left,
            visibility: .all
        )

        let leftChangeTypeDeleted: [DiffChangeType] = [.matching, .deleted, .matching, .missing, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeTypeDeleted)
        let rightChangeTypeDeleted: [DiffChangeType] = [.matching, .missing, .matching, .added, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeTypeDeleted)

        let linesStatus = diffResult.leftSide.lines
        let lineNumbers = [1, 2, 3, -1, 4]

        for (index, line) in linesStatus.enumerated() {
            #expect(line.number == lineNumbers[index])
        }
    }

    @Test func deleteLinesDifferences() {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 5, changed: 1))

        let rowsToDelete = IndexSet([2, 3, 5])

        let filteredDiffResult = DiffResult.justDifferentLines(diffResult)

        DiffResult.deleteLines(
            all: diffResult,
            current: filteredDiffResult,
            rows: rowsToDelete,
            side: .right,
            visibility: .differences
        )

        let leftChangeTypeDeleted: [DiffChangeType] = [.deleted, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: filteredDiffResult.leftSide.lines, expectedValue: leftChangeTypeDeleted)
        let rightChangeTypeDeleted: [DiffChangeType] = [.missing, .changed, .missing, .missing, .missing, .missing]
        assert(lines: filteredDiffResult.rightSide.lines, expectedValue: rightChangeTypeDeleted)

        let linesStatus = filteredDiffResult.rightSide.lines
        let lineNumbers = [-1, 3, -1, -1, -1, -1]

        for (index, line) in linesStatus.enumerated() {
            #expect(line.number == lineNumbers[index])
        }
    }

    @Test func deleteLinesMatches() {
        let leftText = "line1\n\nline2\nline3\nline5\nline7\nline8\nline9"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .changed, .deleted, .deleted, .deleted, .deleted]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .changed, .missing, .missing, .missing, .missing]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 5, changed: 1))

        let rowsToDelete = IndexSet([0])

        let filteredDiffResult = DiffResult.justMatchingLines(diffResult)

        DiffResult.deleteLines(
            all: diffResult,
            current: filteredDiffResult,
            rows: rowsToDelete,
            side: .right,
            visibility: .matches
        )

        let leftChangeTypeDeleted: [DiffChangeType] = [.matching]
        assert(lines: filteredDiffResult.leftSide.lines, expectedValue: leftChangeTypeDeleted)
        let rightChangeTypeDeleted: [DiffChangeType] = [.matching]
        assert(lines: filteredDiffResult.rightSide.lines, expectedValue: rightChangeTypeDeleted)

        let linesStatus = filteredDiffResult.rightSide.lines
        let lineNumbers = [1]

        for (index, line) in linesStatus.enumerated() {
            #expect(line.number == lineNumbers[index])
        }
    }

    @Test func insertLinesLeftDestination() throws {
        let leftText = "line1\n\nline2\nline3"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let newLines = "line2.1\nline2.2\n"
        diffResult.insert(text: newLines, at: 3, side: .left)

        let leftChangeType: [DiffChangeType] = [.matching, .deleted, .matching, .deleted, .deleted, .changed]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .missing, .matching, .missing, .missing, .changed]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 1, changed: 1))

        assertArrayCount(diffResult.sections, 2)
        #expect(diffResult.sections[0] == DiffSection(start: 1, end: 1))
        #expect(diffResult.sections[1] == DiffSection(start: 3, end: 3))

        let expectedLeftLines = [
            (1, "line1"),
            (2, ""),
            (3, "line2"),
            (4, "line2.1"),
            (5, "line2.2"),
            (6, "line3"),
        ]

        let expectedRightLines = [
            (1, "line1"),
            (-1, ""),
            (2, "line2"),
            (-1, ""),
            (-1, ""),
            (3, "line4"),
        ]

        for (index, (leftNumber, leftLine)) in expectedLeftLines.enumerated() {
            let (rightNumber, rightLine) = expectedRightLines[index]
            let diffLeftLine = diffResult.leftSide.lines[index]
            let diffRightLine = diffResult.rightSide.lines[index]

            #expect(leftNumber == diffLeftLine.number)
            #expect(leftLine == diffLeftLine.text)

            #expect(rightNumber == diffRightLine.number)
            #expect(rightLine == diffRightLine.text)
        }
    }

    @Test func insertLinesRightDestination() throws {
        let leftText = "line1\n\nline2\nline3"
        let rightText = "line1\nline2\nline4"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let newLines = "line1.1\nline1.2\n"
        diffResult.insert(text: newLines, at: 1, side: .right)

        let leftChangeType: [DiffChangeType] = [.matching, .changed, .missing, .matching, .changed]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .changed, .added, .matching, .changed]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 1, changed: 1))

        assertArrayCount(diffResult.sections, 2)
        #expect(diffResult.sections[0] == DiffSection(start: 1, end: 1))
        #expect(diffResult.sections[1] == DiffSection(start: 3, end: 3))

        let expectedLeftLines = [
            (1, "line1"),
            (2, ""),
            (-1, ""),
            (3, "line2"),
            (4, "line3"),
        ]

        let expectedRightLines = [
            (1, "line1"),
            (2, "line1.1"),
            (3, "line1.2"),
            (4, "line2"),
            (5, "line4"),
        ]

        for (index, (leftNumber, leftLine)) in expectedLeftLines.enumerated() {
            let (rightNumber, rightLine) = expectedRightLines[index]
            let diffLeftLine = diffResult.leftSide.lines[index]
            let diffRightLine = diffResult.rightSide.lines[index]

            #expect(leftNumber == diffLeftLine.number)
            #expect(leftLine == diffLeftLine.text)

            #expect(rightNumber == diffRightLine.number)
            #expect(rightLine == diffRightLine.text)
        }
    }

    @Test func insertLinesAtBottom() throws {
        let leftText = "line1\nline2\n"
        let rightText = "line1\n"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let newLines = "line2\nline3\nline4"
        diffResult.insert(text: newLines, at: 1, side: .right)
        diffResult.refreshSections()

        let leftChangeType: [DiffChangeType] = [.matching, .matching, .missing, .missing]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .matching, .added, .added]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 2, deleted: 0, changed: 0))

        assertArrayCount(diffResult.sections, 1)
        #expect(diffResult.sections[0] == DiffSection(start: 2, end: 3))

        let expectedLeftLines = [
            (1, "line1"),
            (2, "line2"),
            (-1, ""),
            (-1, ""),
        ]

        let expectedRightLines = [
            (1, "line1"),
            (2, "line2"),
            (3, "line3"),
            (4, "line4"),
        ]

        for (index, (leftNumber, leftLine)) in expectedLeftLines.enumerated() {
            let (rightNumber, rightLine) = expectedRightLines[index]
            let diffLeftLine = diffResult.leftSide.lines[index]
            let diffRightLine = diffResult.rightSide.lines[index]

            #expect(leftNumber == diffLeftLine.number)
            #expect(leftLine == diffLeftLine.text)

            #expect(rightNumber == diffRightLine.number)
            #expect(rightLine == diffRightLine.text)
        }
    }

    @Test func insertOverMatchingLine() throws {
        let leftText = "line1\nline5"
        let rightText = "line1\nline5"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText)

        let newLines = "line2\nline3\nline4"
        diffResult.insert(text: newLines, at: 1, side: .right)
        diffResult.refreshSections()

        let leftChangeType: [DiffChangeType] = [.matching, .missing, .missing, .missing, .matching]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .added, .added, .added, .matching]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 3, deleted: 0, changed: 0))

        assertArrayCount(diffResult.sections, 1)
        #expect(diffResult.sections[0] == DiffSection(start: 1, end: 3))

        let expectedLeftLines = [
            (1, "line1"),
            (-1, ""),
            (-1, ""),
            (-1, ""),
            (2, "line5"),
        ]

        let expectedRightLines = [
            (1, "line1"),
            (2, "line2"),
            (3, "line3"),
            (4, "line4"),
            (5, "line5"),
        ]

        for (index, (leftNumber, leftLine)) in expectedLeftLines.enumerated() {
            let (rightNumber, rightLine) = expectedRightLines[index]
            let diffLeftLine = diffResult.leftSide.lines[index]
            let diffRightLine = diffResult.rightSide.lines[index]

            #expect(leftNumber == diffLeftLine.number)
            #expect(leftLine == diffLeftLine.text)

            #expect(rightNumber == diffRightLine.number)
            #expect(rightLine == diffRightLine.text)
        }
    }
}

// swiftlint:enable file_length
