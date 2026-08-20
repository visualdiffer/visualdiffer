//
//  SequenceDiffTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class SequenceDiffTests: DiffResultBaseTests {
    @Test
    func emptySequences() {
        #expect(changes([], []).isEmpty)
    }

    @Test
    func identicalSequences() {
        #expect(changes(["a", "b", "c"], ["a", "b", "c"]).isEmpty)
    }

    @Test
    func insertedIntoEmptySequence() {
        #expect(changes([], ["a", "b"]) == [DiffChange(line0: 0, line1: 0, deleted: 0, inserted: 2)])
    }

    @Test
    func deletedWholeSequence() {
        #expect(changes(["a", "b"], []) == [DiffChange(line0: 0, line1: 0, deleted: 2, inserted: 0)])
    }

    @Test
    func deletedFromMiddle() {
        #expect(changes(["a", "b", "c"], ["a", "c"]) == [DiffChange(line0: 1, line1: 1, deleted: 1, inserted: 0)])
    }

    @Test
    func replacedElement() {
        #expect(changes(["a", "b", "c"], ["a", "x", "c"]) == [DiffChange(line0: 1, line1: 1, deleted: 1, inserted: 1)])
    }

    @Test
    func twoSeparateHunks() {
        let result = changes(["a", "b", "c", "d", "e"], ["x", "b", "c", "y", "e"])

        #expect(result == [
            DiffChange(line0: 0, line1: 0, deleted: 1, inserted: 1),
            DiffChange(line0: 3, line1: 3, deleted: 1, inserted: 1),
        ])
    }

    @Test
    func blankLineDeletion() {
        let result = changes(["a", "", "b", "", "c"], ["a", "b", "", "c"])

        #expect(result == [DiffChange(line0: 1, line1: 1, deleted: 1, inserted: 0)])
    }

    @Test
    func repeatedRunTrimmedAtBothEnds() {
        let result = changes(["x", "a", "a", "a", "y"], ["a", "a", "a"])

        #expect(result == [
            DiffChange(line0: 0, line1: 0, deleted: 1, inserted: 0),
            DiffChange(line0: 4, line1: 3, deleted: 1, inserted: 0),
        ])
    }

    @Test
    func insertionNextToABlankLine() {
        let result = changes(["a", "b", "", "c", "d"], ["a", "b", "", "x", "", "c", "d"])

        #expect(result == [DiffChange(line0: 3, line1: 3, deleted: 0, inserted: 2)])
    }

    @Test
    func duplicateHeavySequenceKeepsTheDiscardHeuristicHonest() {
        let lineCount = 80
        let distinctCount = 4
        let base = (0 ..< lineCount).map { "line \($0 % distinctCount)" }
        var mutated = base

        mutated[10] = "unique A"
        mutated[40] = "unique B"
        mutated.insert("unique C", at: 60)
        mutated.remove(at: 20)

        #expect(changes(base, mutated) == [
            DiffChange(line0: 10, line1: 10, deleted: 1, inserted: 1),
            DiffChange(line0: 20, line1: 20, deleted: 1, inserted: 0),
            DiffChange(line0: 40, line1: 39, deleted: 1, inserted: 1),
            DiffChange(line0: 60, line1: 59, deleted: 0, inserted: 1),
        ])
    }

    @Test
    func canonicallyEquivalentLinesAreDifferent() {
        let precomposed = "caf\u{00E9}"
        let decomposed = "cafe\u{0301}"

        // String compares the two spellings as equal, the diff engine must not,
        // otherwise a real file difference would be silently hidden
        #expect(precomposed == decomposed)

        #expect(changes([precomposed], [decomposed]) == [DiffChange(line0: 0, line1: 0, deleted: 1, inserted: 1)])
    }

    @Test
    func ignoredDiscardsKeepFrequentElements() {
        // without ignoresDiscards the frequent element would be provisionally discarded
        // and the whole sequence would be reported as changed
        let left = Array(String(repeating: "a", count: 100) + "X" + String(repeating: "a", count: 100))
        let right = Array(String(repeating: "a", count: 100) + "Y" + String(repeating: "a", count: 100))

        let result = SequenceDiff.changes(left: left, right: right, ignoresDiscards: true)

        #expect(result == [DiffChange(line0: 100, line1: 100, deleted: 1, inserted: 1)])
    }

    /// compares through the exact code unit key, as the file comparison does
    private func changes(_ left: [String], _ right: [String]) -> [DiffChange] {
        SequenceDiff.changes(
            left: left.map { SequenceDiff.TextKey($0) },
            right: right.map { SequenceDiff.TextKey($0) }
        )
    }
}
