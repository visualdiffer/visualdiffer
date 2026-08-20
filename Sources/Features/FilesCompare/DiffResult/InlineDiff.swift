//
//  InlineDiff.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

/// character level differences between the two lines of a changed pair
///
/// The ranges are character offsets into the line text, ascending and non overlapping.
/// A pure insertion leaves the left side without ranges, a pure deletion leaves
/// the right side without ranges.
struct InlineDiff {
    /// above this length the character comparison degrades to a single range per side,
    /// generated or minified lines would otherwise make the comparison too slow
    private static let maxDiffableLength = 2000

    static let empty = InlineDiff(leftRanges: [], rightRanges: [])

    let leftRanges: [Range<Int>]
    let rightRanges: [Range<Int>]

    // only ignoreCharacterCase is honoured, the whitespace options drive the line
    // comparison and are not applied inside a line
    static func between(
        _ left: DiffLineComponent,
        _ right: DiffLineComponent,
        options: DiffResult.Options
    ) -> InlineDiff {
        // the length is checked before building the keys, a very long line would
        // otherwise allocate one key per character just to be degraded right after
        if left.text.count > maxDiffableLength || right.text.count > maxDiffableLength {
            return spanningDifference(left.text, right.text, options: options)
        }
        let leftKeys = keys(of: left.text, options: options)
        let rightKeys = keys(of: right.text, options: options)

        if leftKeys == rightKeys {
            return empty
        }
        // the discard heuristic must be skipped here, on a single line it would report
        // every frequent character as changed
        let changes = SequenceDiff.changes(
            left: leftKeys,
            right: rightKeys,
            ignoresDiscards: true
        )
        var leftRanges = [Range<Int>]()
        var rightRanges = [Range<Int>]()

        for change in changes {
            if change.deleted > 0 {
                leftRanges.append(change.line0 ..< change.line0 + change.deleted)
            }

            if change.inserted > 0 {
                rightRanges.append(change.line1 ..< change.line1 + change.inserted)
            }
        }

        return InlineDiff(leftRanges: leftRanges, rightRanges: rightRanges)
    }

    /// one key per character, so the reported offsets stay character offsets while the
    /// comparison keeps the exact code unit semantics the diff engine needs
    private static func keys(
        of text: String,
        options: DiffResult.Options
    ) -> [SequenceDiff.TextKey] {
        text.map { key(for: $0, options: options) }
    }

    private static func key(
        for character: Character,
        options: DiffResult.Options
    ) -> SequenceDiff.TextKey {
        options.contains(.ignoreCharacterCase)
            ? SequenceDiff.TextKey(character.lowercased())
            : SequenceDiff.TextKey(String(character))
    }

    // a single range per side, covering everything between the common prefix and the
    // common suffix, walked without building any array
    private static func spanningDifference(
        _ leftText: String,
        _ rightText: String,
        options: DiffResult.Options
    ) -> InlineDiff {
        let leftCount = leftText.count
        let rightCount = rightText.count
        let shortest = min(leftCount, rightCount)
        var prefix = 0

        for (leftCharacter, rightCharacter) in zip(leftText, rightText) {
            if key(for: leftCharacter, options: options) != key(for: rightCharacter, options: options) {
                break
            }
            prefix += 1
        }
        var suffix = 0

        for (leftCharacter, rightCharacter) in zip(leftText.reversed(), rightText.reversed()) {
            if suffix >= shortest - prefix {
                break
            }

            if key(for: leftCharacter, options: options) != key(for: rightCharacter, options: options) {
                break
            }
            suffix += 1
        }

        return InlineDiff(
            leftRanges: ranges(from: prefix, to: leftCount - suffix),
            rightRanges: ranges(from: prefix, to: rightCount - suffix)
        )
    }

    private static func ranges(from lower: Int, to upper: Int) -> [Range<Int>] {
        lower < upper ? [lower ..< upper] : []
    }

    // the first line takes the ranges of the left side
    static func apply(
        to firstLine: DiffLine,
        and secondLine: DiffLine,
        options: DiffResult.Options
    ) {
        let inlineDiff = between(firstLine.component, secondLine.component, options: options)

        firstLine.inlineRanges = inlineDiff.leftRanges
        secondLine.inlineRanges = inlineDiff.rightRanges
    }
}
