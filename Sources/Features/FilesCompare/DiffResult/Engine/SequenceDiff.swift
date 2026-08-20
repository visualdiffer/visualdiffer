//
//  SequenceDiff.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

/// GNU diff comparison, it finds the differences between two sequences of hashable
/// elements and reports them as an edit script
///
/// Ported from the legacy UnifiedDiff Objective-C engine, the algorithm is unchanged:
/// a bidirectional breadth-first search of the edit matrix, preceded by the heuristic
/// that discards the elements matching nothing or matching too many elements of the
/// other sequence, and followed by the boundary shifting that makes the hunks prettier.
final class SequenceDiff {
    /// text element compared by exact code units
    ///
    /// String and Character consider canonically equivalent spellings equal, for example
    /// "é" and "e" followed by a combining acute accent, so using them directly as keys
    /// would silently hide a real difference between two files.
    struct TextKey: Hashable {
        let text: String

        init(_ text: String) {
            self.text = text
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.text.utf8.elementsEqual(rhs.text.utf8)
        }

        func hash(into hasher: inout Hasher) {
            var copy = text

            copy.withUTF8 {
                hasher.combine(bytes: UnsafeRawBufferPointer($0))
            }
        }
    }

    // the diagonals run from -rightCount to leftCount, plus a sentinel at each end
    private static let diagonalPadding = 3

    private let leftData: DiffFileData
    private let rightData: DiffFileData

    /// vectors being compared, they hold the equivalence codes of the nondiscarded elements
    private var leftVector = [Int]()
    private var rightVector = [Int]()

    /// vector, indexed by diagonal, containing the X coordinate of the point furthest
    /// along the given diagonal in the forward search of the edit matrix
    private var forwardDiagonals = [Int]()

    /// vector, indexed by diagonal, containing the X coordinate of the point furthest
    /// along the given diagonal in the backward search of the edit matrix
    private var backwardDiagonals = [Int]()

    private var diagonalOffset = 0

    private init(
        leftData: DiffFileData,
        rightData: DiffFileData
    ) {
        self.leftData = leftData
        self.rightData = rightData
    }

    /// Compares two sequences and reports their differences.
    ///
    /// Each element is translated to an equivalence code, the original elements are no
    /// longer needed to compute the differences.
    /// - Parameters:
    ///   - ignoresDiscards: when true the algorithm returns a guaranteed minimal set of
    ///     changes, skipping the heuristic that discards confusing elements. It must be
    ///     used on short sequences, where discarding the elements matching too many
    ///     others would report almost everything as changed
    /// - Returns: the changes in ascending element order
    static func changes<Key: Hashable>(
        left: [Key],
        right: [Key],
        ignoresDiscards: Bool = false
    ) -> [DiffChange] {
        var table = EquivalenceTable<Key>()
        let leftCodes = table.encode(left)
        let rightCodes = table.encode(right)
        let codeCount = table.codeCount

        let diff = SequenceDiff(
            leftData: DiffFileData(
                equivalences: leftCodes,
                codeCount: codeCount,
                ignoresDiscards: ignoresDiscards
            ),
            rightData: DiffFileData(
                equivalences: rightCodes,
                codeCount: codeCount,
                ignoresDiscards: ignoresDiscards
            )
        )

        return diff.changes()
    }

    private func changes() -> [DiffChange] {
        // some elements are obviously insertions or deletions because they don't match
        // anything, detect them now and avoid even thinking about them
        // in the main comparison algorithm
        leftData.discardConfusingElements(against: rightData)
        rightData.discardConfusingElements(against: leftData)

        // now do the main comparison algorithm, considering just the nondiscarded elements
        leftVector = leftData.undiscarded
        rightVector = rightData.undiscarded

        let diagonals = leftData.nonDiscardedCount + rightData.nonDiscardedCount + Self.diagonalPadding

        diagonalOffset = rightData.nonDiscardedCount + 1
        forwardDiagonals = Array(repeating: 0, count: diagonals)
        backwardDiagonals = Array(repeating: 0, count: diagonals)

        compareSequences(
            xoff: 0,
            xlim: leftData.nonDiscardedCount,
            yoff: 0,
            ylim: rightData.nonDiscardedCount
        )

        forwardDiagonals = []
        backwardDiagonals = []

        // modify the results slightly to make them prettier
        // in cases where that can validly be done
        leftData.shiftBoundaries(against: rightData)
        rightData.shiftBoundaries(against: leftData)

        return buildScript()
    }

    /// Compare in detail contiguous subsequences of the two sequences which are known,
    /// as a whole, to match each other.
    ///
    /// The results are recorded by marking as changed each element that is an insertion
    /// or a deletion. The subsequence of the left side is `[xoff, xlim)` and likewise
    /// `[yoff, ylim)` for the right one, all element numbers are origin-0 and the
    /// discarded elements are not counted.
    private func compareSequences(
        xoff: Int,
        xlim: Int,
        yoff: Int,
        ylim: Int
    ) {
        var xoff = xoff
        var xlim = xlim
        var yoff = yoff
        var ylim = ylim

        // slide down the bottom initial diagonal
        while xoff < xlim, yoff < ylim, leftVector[xoff] == rightVector[yoff] {
            xoff += 1
            yoff += 1
        }
        // slide up the top initial diagonal
        while xlim > xoff, ylim > yoff, leftVector[xlim - 1] == rightVector[ylim - 1] {
            xlim -= 1
            ylim -= 1
        }

        // handle simple cases
        if xoff == xlim {
            while yoff < ylim {
                rightData.markChanged(virtualIndex: yoff)
                yoff += 1
            }
        } else if yoff == ylim {
            while xoff < xlim {
                leftData.markChanged(virtualIndex: xoff)
                xoff += 1
            }
        } else {
            // find a point of correspondence in the middle of the sequences
            let diagonal = middleSnake(xoff: xoff, xlim: xlim, yoff: yoff, ylim: ylim)
            let backward = backwardDiagonals[diagonalOffset + diagonal]

            // use that point to split this problem into two subproblems
            compareSequences(xoff: xoff, xlim: backward, yoff: yoff, ylim: backward - diagonal)
            // this used to use the forward value instead of the backward one, but that is
            // incorrect, it is not necessarily the case that the diagonal has a snake
            // from the backward point to the forward one
            compareSequences(xoff: backward, xlim: xlim, yoff: backward - diagonal, ylim: ylim)
        }
    }

    /// Find the midpoint of the shortest edit script for a specified portion
    /// of the two sequences.
    ///
    /// We scan from the beginnings of the sequences, and simultaneously from the ends,
    /// doing a breadth-first search through the space of edit-sequence.
    /// When the two searches meet, we have found the midpoint of the shortest edit sequence.
    ///
    /// This function assumes that the first elements of the specified portions of the two
    /// sequences do not match, and likewise that the last elements do not match, the caller
    /// must trim the matching elements from the beginning and the end of the portions it
    /// is going to specify.
    ///
    /// Note that if we return the "wrong" diagonal value, or if the backward value at that
    /// diagonal is "wrong", the worst this can do is cause suboptimal output, it cannot
    /// cause incorrect output.
    /// - Returns: the number of the diagonal on which the midpoint lies, the diagonal number
    ///   equals the number of inserted elements minus the number of deleted ones, counting
    ///   only the elements before the midpoint
    private func middleSnake(
        xoff: Int,
        xlim: Int,
        yoff: Int,
        ylim: Int
    ) -> Int {
        // minimum and maximum valid diagonal
        let dmin = xoff - ylim
        let dmax = xlim - yoff
        // center diagonal of the top-down and of the bottom-up search
        let fmid = xoff - yoff
        let bmid = xlim - ylim
        // limits of the top-down and of the bottom-up search
        var fmin = fmid
        var fmax = fmid
        var bmin = bmid
        var bmax = bmid
        // true if southeast corner is on an odd diagonal with respect to the northwest
        let odd = ((fmid - bmid) & 1) != 0

        forwardDiagonals[diagonalOffset + fmid] = xoff
        backwardDiagonals[diagonalOffset + bmid] = xlim

        while true {
            // extend the top-down search by an edit step in each diagonal
            if fmin > dmin {
                fmin -= 1
                forwardDiagonals[diagonalOffset + fmin - 1] = -1
            } else {
                fmin += 1
            }

            if fmax < dmax {
                fmax += 1
                forwardDiagonals[diagonalOffset + fmax + 1] = -1
            } else {
                fmax -= 1
            }
            var diagonal = fmax

            while diagonal >= fmin {
                let low = forwardDiagonals[diagonalOffset + diagonal - 1]
                let high = forwardDiagonals[diagonalOffset + diagonal + 1]
                var x = low >= high ? low + 1 : high
                var y = x - diagonal

                while x < xlim, y < ylim, leftVector[x] == rightVector[y] {
                    x += 1
                    y += 1
                }
                forwardDiagonals[diagonalOffset + diagonal] = x

                if odd, bmin <= diagonal, diagonal <= bmax,
                   backwardDiagonals[diagonalOffset + diagonal] <= x {
                    return diagonal
                }
                diagonal -= 2
            }

            // similarly extend the bottom-up search
            if bmin > dmin {
                bmin -= 1
                backwardDiagonals[diagonalOffset + bmin - 1] = .max
            } else {
                bmin += 1
            }

            if bmax < dmax {
                bmax += 1
                backwardDiagonals[diagonalOffset + bmax + 1] = .max
            } else {
                bmax -= 1
            }
            diagonal = bmax

            while diagonal >= bmin {
                let low = backwardDiagonals[diagonalOffset + diagonal - 1]
                let high = backwardDiagonals[diagonalOffset + diagonal + 1]
                var x = low < high ? low : high - 1
                var y = x - diagonal

                while x > xoff, y > yoff, leftVector[x - 1] == rightVector[y - 1] {
                    x -= 1
                    y -= 1
                }
                backwardDiagonals[diagonalOffset + diagonal] = x

                if !odd, fmin <= diagonal, diagonal <= fmax,
                   x <= forwardDiagonals[diagonalOffset + diagonal] {
                    return diagonal
                }
                diagonal -= 2
            }
        }
    }

    /// Scan the tables of which elements are inserted and deleted, producing an edit script.
    ///
    /// The tables are walked backwards, so the changes are collected in reverse order
    /// and reversed before being returned.
    private func buildScript() -> [DiffChange] {
        var changes = [DiffChange]()
        // the flags are origin-1, index 0 and the last one are the always false sentinels
        var index0 = leftData.count
        var index1 = rightData.count
        let leftChanged = leftData.changedFlags
        let rightChanged = rightData.changedFlags

        while index0 >= 0 || index1 >= 0 {
            if leftChanged[index0] || rightChanged[index1] {
                let line0 = index0
                let line1 = index1

                // find how many elements changed here in each sequence
                while leftChanged[index0] {
                    index0 -= 1
                }

                while rightChanged[index1] {
                    index1 -= 1
                }
                changes.append(DiffChange(
                    line0: index0,
                    line1: index1,
                    deleted: line0 - index0,
                    inserted: line1 - index1
                ))
            }
            // we have reached elements in the two sequences that match each other
            index0 -= 1
            index1 -= 1
        }

        return Array(changes.reversed())
    }
}
