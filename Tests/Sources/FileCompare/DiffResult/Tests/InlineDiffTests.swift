//
//  InlineDiffTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class InlineDiffTests: DiffResultBaseTests {
    private static let longLineLength = 3000

    @Test
    func identicalLines() {
        let diff = inlineDiff("hello", "hello")

        #expect(diff.leftRanges.isEmpty)
        #expect(diff.rightRanges.isEmpty)
    }

    @Test
    func emptyLines() {
        let diff = inlineDiff("", "")

        #expect(diff.leftRanges.isEmpty)
        #expect(diff.rightRanges.isEmpty)
    }

    @Test
    func emptyAgainstFilledLine() {
        let diff = inlineDiff("", "abc")

        #expect(diff.leftRanges.isEmpty)
        #expect(diff.rightRanges == [0 ..< 3])
    }

    @Test
    func oneCharacterInTheMiddle() {
        let diff = inlineDiff("abcde", "abXde")

        #expect(diff.leftRanges == [2 ..< 3])
        #expect(diff.rightRanges == [2 ..< 3])
    }

    @Test
    func changeAtTheStart() {
        let diff = inlineDiff("Xbcde", "abcde")

        #expect(diff.leftRanges == [0 ..< 1])
        #expect(diff.rightRanges == [0 ..< 1])
    }

    @Test
    func changeAtTheEnd() {
        let diff = inlineDiff("abcdX", "abcde")

        #expect(diff.leftRanges == [4 ..< 5])
        #expect(diff.rightRanges == [4 ..< 5])
    }

    @Test
    func pureInsertion() {
        let diff = inlineDiff("abc", "abXYc")

        #expect(diff.leftRanges.isEmpty)
        #expect(diff.rightRanges == [2 ..< 4])
    }

    @Test
    func pureDeletion() {
        let diff = inlineDiff("abXYc", "abc")

        #expect(diff.leftRanges == [2 ..< 4])
        #expect(diff.rightRanges.isEmpty)
    }

    @Test
    func severalDisjointChanges() {
        let diff = inlineDiff("abcXefgYijk", "abcQefgRijk")

        #expect(diff.leftRanges == [3 ..< 4, 7 ..< 8])
        #expect(diff.rightRanges == [3 ..< 4, 7 ..< 8])
    }

    @Test
    func changedIdentifierKeepsCommonPrefixAndSuffix() {
        let diff = inlineDiff("let value = computeTotal(a, b)", "let value = computeSum(a, b)")

        #expect(diff.leftRanges == [19 ..< 24])
        #expect(diff.rightRanges == [19 ..< 22])
    }

    @Test
    func characterCaseIsHonouredOnlyWhenIgnored() {
        let sensitive = inlineDiff("Hello", "hello")
        let insensitive = inlineDiff("Hello", "hello", options: [.ignoreCharacterCase])

        #expect(sensitive.leftRanges == [0 ..< 1])
        #expect(sensitive.rightRanges == [0 ..< 1])
        #expect(insensitive.leftRanges.isEmpty)
        #expect(insensitive.rightRanges.isEmpty)
    }

    @Test
    func canonicallyEquivalentCharactersAreDifferent() {
        let precomposed = "caf\u{00E9}"
        let decomposed = "cafe\u{0301}"

        // Character compares the two spellings as equal and both count as one character,
        // the comparison must still report the difference
        #expect(precomposed == decomposed)
        #expect(precomposed.count == decomposed.count)

        let diff = inlineDiff(precomposed, decomposed)

        #expect(diff.leftRanges == [3 ..< 4])
        #expect(diff.rightRanges == [3 ..< 4])
    }

    @Test
    func canonicallyEquivalentCharactersDifferWhileIgnoringCase() {
        let diff = inlineDiff("CAF\u{00C9}", "cafe\u{0301}", options: [.ignoreCharacterCase])

        #expect(diff.leftRanges == [3 ..< 4])
        #expect(diff.rightRanges == [3 ..< 4])
    }

    @Test
    func canonicallyEquivalentLinesAreReportedAsChanged() {
        let diffResult = DiffResult()
        diffResult.diff(leftText: "caf\u{00E9}\nsecond", rightText: "cafe\u{0301}\nsecond")

        #expect(diffResult.leftSide.lines[0].type == .changed)
        #expect(diffResult.rightSide.lines[0].type == .changed)
        #expect(diffResult.leftSide.lines[0].inlineRanges == [3 ..< 4])
        #expect(diffResult.rightSide.lines[0].inlineRanges == [3 ..< 4])
        #expect(diffResult.leftSide.lines[1].type == .matching)
    }

    @Test
    func longLinesDegradeToASingleRange() {
        let filler = String(repeating: "a", count: Self.longLineLength)
        let diff = inlineDiff(filler + "X" + filler, filler + "Y" + filler)

        #expect(diff.leftRanges == [Self.longLineLength ..< Self.longLineLength + 1])
        #expect(diff.rightRanges == [Self.longLineLength ..< Self.longLineLength + 1])
    }

    @Test
    func longIdenticalLinesHaveNoRanges() {
        let filler = String(repeating: "a", count: Self.longLineLength)
        let diff = inlineDiff(filler, filler)

        #expect(diff.leftRanges.isEmpty)
        #expect(diff.rightRanges.isEmpty)
    }

    @Test
    func longLineAgainstItsOwnPrefix() {
        let filler = String(repeating: "a", count: Self.longLineLength)
        let diff = inlineDiff(filler, filler + "X")

        #expect(diff.leftRanges.isEmpty)
        #expect(diff.rightRanges == [Self.longLineLength ..< Self.longLineLength + 1])
    }

    @Test
    func longLineChangedAtTheStart() {
        let filler = String(repeating: "a", count: Self.longLineLength)
        let diff = inlineDiff("X" + filler, "Y" + filler)

        #expect(diff.leftRanges == [0 ..< 1])
        #expect(diff.rightRanges == [0 ..< 1])
    }

    @Test
    func longLineChangedAtTheEnd() {
        let filler = String(repeating: "a", count: Self.longLineLength)
        let diff = inlineDiff(filler + "X", filler + "Y")

        #expect(diff.leftRanges == [Self.longLineLength ..< Self.longLineLength + 1])
        #expect(diff.rightRanges == [Self.longLineLength ..< Self.longLineLength + 1])
    }

    @Test
    func longLinesIgnoringCharacterCase() {
        let filler = String(repeating: "a", count: Self.longLineLength)
        let diff = inlineDiff(filler + "X", filler.uppercased() + "y", options: [.ignoreCharacterCase])

        #expect(diff.leftRanges == [Self.longLineLength ..< Self.longLineLength + 1])
        #expect(diff.rightRanges == [Self.longLineLength ..< Self.longLineLength + 1])
    }

    @Test
    func longLinesKeepTheExactComparison() {
        let filler = String(repeating: "a", count: Self.longLineLength)
        let diff = inlineDiff(filler + "caf\u{00E9}" + filler, filler + "cafe\u{0301}" + filler)
        let expected = [Self.longLineLength + 3 ..< Self.longLineLength + 4]

        #expect(diff.leftRanges == expected)
        #expect(diff.rightRanges == expected)
    }

    @Test
    func changedPairCarriesRanges() {
        let diffResult = DiffResult()
        diffResult.diff(leftText: "alpha\nbeta1\ngamma", rightText: "alpha\nbeta2\ngamma")

        #expect(diffResult.leftSide.lines[1].type == .changed)
        #expect(diffResult.leftSide.lines[1].inlineRanges == [4 ..< 5])
        #expect(diffResult.rightSide.lines[1].inlineRanges == [4 ..< 5])
        #expect(diffResult.leftSide.lines[0].inlineRanges.isEmpty)
        #expect(diffResult.leftSide.lines[2].inlineRanges.isEmpty)
    }

    @Test
    func replacingComponentClearsRanges() {
        let line = DiffLine(
            with: .changed,
            number: 1,
            component: DiffLineComponent(text: "abc", eol: .unix)
        )
        line.inlineRanges = [0 ..< 1]

        line.component = DiffLineComponent(text: "xyz", eol: .unix)

        #expect(line.inlineRanges.isEmpty)
    }

    @Test
    func missingLineClearsRanges() {
        let line = DiffLine(
            with: .changed,
            number: 1,
            component: DiffLineComponent(text: "abc", eol: .unix)
        )
        line.inlineRanges = [0 ..< 1]

        line.makeMissing()

        #expect(line.inlineRanges.isEmpty)
    }

    private func inlineDiff(
        _ leftText: String,
        _ rightText: String,
        options: DiffResult.Options = []
    ) -> InlineDiff {
        InlineDiff.between(
            DiffLineComponent(text: leftText, eol: .missing),
            DiffLineComponent(text: rightText, eol: .missing),
            options: options
        )
    }
}
