//
//  WhitespacesTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/12/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class WhitespacesTests: DiffResultBaseTests {
    @Test
    func ignoreLeadingWhitespaces() {
        let leftText =
            "    leading spaces\n" +
            "  another line"
        let rightText =
            " leading spaces\n" +
            "another line"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText, options: .ignoreLeadingWhitespaces)

        let leftChangeType: [DiffChangeType] = [.matching, .matching]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .matching]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 0, changed: 0))

        assertArrayCount(diffResult.sections, 0)
    }

    @Test
    func ignoreInternalWhitespaces() {
        let leftText =
            "   line1\n" +
            "another    text\t\ttabs and  spaces"
        let rightText =
            "line1\n" +
            "another text tabs and spaces"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText, options: .ignoreInternalWhitespaces)

        let leftChangeType: [DiffChangeType] = [.changed, .matching]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.changed, .matching]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 1, added: 0, deleted: 0, changed: 1))

        assertArrayCount(diffResult.sections, 1)
    }

    @Test
    func ignoreAllWhitespaces() {
        let leftText =
            "   line1\n" +
            "another    text\t\ttabs and  spaces\r\n" +
            "last line     "
        let rightText =
            "line1\n" +
            "another text tabs and spaces\n" +
            "    last line"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText, options: [.allIgnoreWhitespaces, .ignoreLineEndings])

        let leftChangeType: [DiffChangeType] = [.matching, .matching, .matching]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .matching, .matching]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 3, added: 0, deleted: 0, changed: 0))

        assertArrayCount(diffResult.sections, 0)
    }

    @Test("Ignore all whitespaces differences but compare EOLs")
    func ignoreAllWhitespacesThenEol() {
        let leftText =
            "   line1\n" +
            "another    text\t\ttabs and  spaces\r\n" +
            "last line     "
        let rightText =
            "line1\n" +
            "another text tabs and spaces\n" +
            "    last line"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText, options: [.allIgnoreWhitespaces])

        let leftChangeType: [DiffChangeType] = [.matching, .changed, .matching]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .changed, .matching]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 0, changed: 1))

        assertArrayCount(diffResult.sections, 1)
    }

    @Test
    func ignoreCharacterCase() {
        let leftText =
            "LINE ONE\n" +
            "Another Line"
        let rightText =
            "line One\n" +
            "another line"

        let diffResult = DiffResult()
        diffResult.diff(leftText: leftText, rightText: rightText, options: .ignoreCharacterCase)

        let leftChangeType: [DiffChangeType] = [.matching, .matching]
        assert(lines: diffResult.leftSide.lines, expectedValue: leftChangeType)
        let rightChangeType: [DiffChangeType] = [.matching, .matching]
        assert(lines: diffResult.rightSide.lines, expectedValue: rightChangeType)

        assert(sectionSeparators: diffResult.leftSide.lines, isSeparator: false)
        assert(sectionSeparators: diffResult.rightSide.lines, isSeparator: false)

        #expect(diffResult.summary == DiffSummary(matching: 2, added: 0, deleted: 0, changed: 0))

        assertArrayCount(diffResult.sections, 0)
    }
}
