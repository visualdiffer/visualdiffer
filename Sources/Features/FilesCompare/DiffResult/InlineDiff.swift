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

    let leftRanges: [Range<Int>]
    let rightRanges: [Range<Int>]

    // only ignoreCharacterCase is honoured, the whitespace options drive the line
    // comparison and are not applied inside a line
    static func between(
        _ left: DiffLineComponent,
        _ right: DiffLineComponent,
        options: DiffResult.Options
    ) -> InlineDiff {
        let leftCount = left.text.count
        let rightCount = right.text.count
        let (prefix, suffix) = commonAffixes(
            left.text,
            right.text,
            shortest: min(leftCount, rightCount),
            options: options
        )
        let leftRange = prefix ..< leftCount - suffix
        let rightRange = prefix ..< rightCount - suffix

        // with one side left empty the other one is a pure insertion or deletion, and
        // past the length or the pair limit the exact ranges are not worth their cost,
        // all degrade to the single range already delimited by the prefix and the suffix
        if leftRange.isEmpty
            || rightRange.isEmpty
            || leftCount > maxDiffableLength
            || rightCount > maxDiffableLength
            || leftRange.count * rightRange.count > maxDiffablePairs {
            return InlineDiff(
                leftRanges: ranges(from: leftRange.lowerBound, to: leftRange.upperBound),
                rightRanges: ranges(from: rightRange.lowerBound, to: rightRange.upperBound)
            )
        }
        // the discard heuristic must be skipped here, on a single line it would report
        // every frequent character as changed
        let changes = SequenceDiff.changes(
            left: keys(of: left.text, in: leftRange, options: options),
            right: keys(of: right.text, in: rightRange, options: options),
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

    /// one key per character of the range, so the reported offsets stay character offsets
    /// while the comparison keeps the exact code unit semantics the diff engine needs
    private static func keys(
        of text: String,
        in range: Range<Int>,
        options: DiffResult.Options
    ) -> [SequenceDiff.TextKey] {
        text.dropFirst(range.lowerBound)
            .prefix(range.count)
            .map { key(for: $0, options: options) }
    }

    private static func key(
        for character: Character,
        options: DiffResult.Options
    ) -> SequenceDiff.TextKey {
        options.contains(.ignoreCharacterCase)
            ? SequenceDiff.TextKey(character.lowercased())
            : SequenceDiff.TextKey(String(character))
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

    // the common prefix and the common suffix cannot hold a difference, they are walked
    // on the text so that the characters they cover are never turned into keys
    private static func commonAffixes(
        _ leftText: String,
        _ rightText: String,
        shortest: Int,
        options: DiffResult.Options
    ) -> (prefix: Int, suffix: Int) {
        var prefix = 0

        for (leftCharacter, rightCharacter) in zip(leftText, rightText) {
            if key(for: leftCharacter, options: options) != key(for: rightCharacter, options: options) {
                break
            }
            prefix += 1
        }
        // the prefix is skipped so the two runs cannot overlap on the shorter line
        let available = shortest - prefix
        var suffix = 0

        for (leftCharacter, rightCharacter) in zip(leftText.reversed(), rightText.reversed()) {
            if suffix >= available {
                break
            }

            if key(for: leftCharacter, options: options) != key(for: rightCharacter, options: options) {
                break
            }
            suffix += 1
        }

        return (prefix, suffix)
    }

    /// joins the differences a short run of equal characters keeps apart, so a field
    /// rewritten as a whole is reported as a whole
    ///
    /// The run is merged into the difference that swallows it, the two sides keep the
    /// same ranges they would have with the run reported as changed.
    private static func aggregated(_ changes: [DiffChange]) -> [DiffChange] {
        var merged = [DiffChange]()

        for change in changes {
            // the equal characters between two differences are the same on both sides,
            // so the left run measures the right one too
            guard let previous = merged.last,
                  change.line0 - (previous.line0 + previous.deleted) <= maxAggregatedRunLength
            else {
                merged.append(change)
                continue
            }

            merged[merged.count - 1] = DiffChange(
                line0: previous.line0,
                line1: previous.line1,
                deleted: change.line0 + change.deleted - previous.line0,
                inserted: change.line1 + change.inserted - previous.line1
            )
        }

        return merged
    }
}
