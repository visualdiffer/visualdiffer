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

    /// above this many character pairs left once the common prefix and suffix are gone
    /// the two lines share almost nothing, the exact comparison would cost far more than
    /// the single range per side it refines
    private static let maxDiffablePairs = 16384

    /// two differences separated by an equal run no longer than this are reported as a
    /// single one, a lone equal character in the middle of a rewritten field would
    /// otherwise scatter the highlight over it
    private static let maxAggregatedRunLength = 1

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
        // the common prefix and the common suffix cannot hold a difference, dropping them
        // keeps the comparison exact and leaves the engine a fraction of the characters
        let prefix = commonPrefixLength(leftKeys, rightKeys)
        let suffix = commonSuffixLength(leftKeys, rightKeys, skipping: prefix)
        let leftRange = prefix ..< leftKeys.count - suffix
        let rightRange = prefix ..< rightKeys.count - suffix

        // with one side left empty the other one is a pure insertion or deletion, and
        // past the pair limit the exact ranges are not worth their cost, both degrade
        // to the single range already delimited by the prefix and the suffix
        if leftRange.isEmpty
            || rightRange.isEmpty
            || leftRange.count * rightRange.count > maxDiffablePairs {
            return InlineDiff(
                leftRanges: ranges(from: leftRange.lowerBound, to: leftRange.upperBound),
                rightRanges: ranges(from: rightRange.lowerBound, to: rightRange.upperBound)
            )
        }
        // the discard heuristic must be skipped here, on a single line it would report
        // every frequent character as changed
        let changes = SequenceDiff.changes(
            left: Array(leftKeys[leftRange]),
            right: Array(rightKeys[rightRange]),
            ignoresDiscards: true
        )
        var leftRanges = [Range<Int>]()
        var rightRanges = [Range<Int>]()

        // the engine compared the characters left between the prefix and the suffix, its
        // offsets are relative to them
        for change in aggregated(changes) {
            if change.deleted > 0 {
                let start = prefix + change.line0
                leftRanges.append(start ..< start + change.deleted)
            }

            if change.inserted > 0 {
                let start = prefix + change.line1
                rightRanges.append(start ..< start + change.inserted)
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

    private static func commonPrefixLength(
        _ leftKeys: [SequenceDiff.TextKey],
        _ rightKeys: [SequenceDiff.TextKey]
    ) -> Int {
        let shortest = min(leftKeys.count, rightKeys.count)
        var length = 0

        while length < shortest, leftKeys[length] == rightKeys[length] {
            length += 1
        }

        return length
    }

    // the prefix is skipped so the two runs cannot overlap on the shorter line
    private static func commonSuffixLength(
        _ leftKeys: [SequenceDiff.TextKey],
        _ rightKeys: [SequenceDiff.TextKey],
        skipping prefix: Int
    ) -> Int {
        let available = min(leftKeys.count, rightKeys.count) - prefix
        var length = 0

        while length < available,
              leftKeys[leftKeys.count - 1 - length] == rightKeys[rightKeys.count - 1 - length] {
            length += 1
        }

        return length
    }

    /// joins the differences a short run of equal characters keeps apart, so a field
    /// rewritten as a whole is reported as a whole
    ///
    /// The run is merged into the difference that swallows it, the two sides keep the
    /// same ranges they would have with the run reported as changed.
    private static func aggregated(_ changes: [DiffChange]) -> [DiffChange] {
        var aggregated = [DiffChange]()

        for change in changes {
            // the equal characters between two differences are the same on both sides,
            // so the left run measures the right one too
            guard let previous = aggregated.last,
                  change.line0 - (previous.line0 + previous.deleted) <= maxAggregatedRunLength
            else {
                aggregated.append(change)
                continue
            }
            aggregated[aggregated.count - 1] = DiffChange(
                line0: previous.line0,
                line1: previous.line1,
                deleted: change.line0 + change.deleted - previous.line0,
                inserted: change.line1 + change.inserted - previous.line1
            )
        }

        return aggregated
    }
}
