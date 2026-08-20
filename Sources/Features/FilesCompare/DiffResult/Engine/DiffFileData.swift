//
//  DiffFileData.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

/// data on one input sequence being compared
final class DiffFileData {
    /// how a single element is classified before the comparison runs
    private enum Discard {
        case keep
        case discardable
        case provisional
    }

    private static let manyMatches = 5
    private static let matchScaleDivisor = 64
    private static let provisionalRunDivisor = 4
    private static let nonProvisionalRunLength = 3
    private static let provisionalScanLimit = 8

    /// vector, indexed by element number, containing an equivalence code for each element,
    /// it is this vector that is actually compared with that of another sequence
    private let equivalences: [Int]

    /// array, indexed by real origin-1 element number, containing true for an element
    /// that is an insertion or a deletion
    private(set) var changedFlags = [Bool]()

    /// vector, like `equivalences` except that the elements for discarded ones
    /// have been squeezed out
    private(set) var undiscarded: [Int]

    /// vector mapping virtual element numbers (not counting discarded elements) to real
    /// ones (counting those elements), both are origin-0
    private var realIndexes: [Int]

    /// total number of nondiscarded elements
    private(set) var nonDiscardedCount = 0

    /// when true nothing is discarded and the comparison considers the whole sequence
    private let ignoresDiscards: Bool

    private let codeCount: Int

    var count: Int {
        equivalences.count
    }

    init(
        equivalences: [Int],
        codeCount: Int,
        ignoresDiscards: Bool
    ) {
        self.equivalences = equivalences
        self.codeCount = codeCount
        self.ignoresDiscards = ignoresDiscards
        undiscarded = Array(repeating: 0, count: equivalences.count)
        realIndexes = Array(repeating: 0, count: equivalences.count)
    }

    /// Discard elements that have no matches in another sequence.
    ///
    /// A discarded element will not be considered by the actual comparison algorithm,
    /// it will be as if that element were not in the sequence.
    /// The `realIndexes` table maps virtual element numbers (which don't count the discarded
    /// elements) into real element numbers, this is how the actual comparison algorithm
    /// produces results that are comprehensible when the discarded elements are counted.
    ///
    /// When an element is discarded it is also marked as a deletion or insertion
    /// so that it will be reported in the edit script.
    /// - Parameter other: the sequence being compared against
    func discardConfusingElements(against other: DiffFileData) {
        clearChangedFlags()

        // set up table of which elements are going to be discarded
        var discards = discardable(counts: other.equivalenceCounts())

        // don't really discard the provisional elements except when they occur
        // in a run of discardables, with nonprovisionals at the beginning and end
        filterDiscards(&discards)

        // actually discard the elements
        discard(discards)
    }

    /// Adjust inserts/deletes of blank elements to join changes as much as possible.
    ///
    /// We do something when a run of changed elements include a blank element at one end
    /// and have an excluded blank element at the other.
    /// We are free to choose which blank element is included, the comparison always chooses
    /// the one at the beginning, but usually it is cleaner to consider the following blank
    /// element to be the "change". The only exception is if the preceding blank element
    /// would join this change to other changes.
    /// - Parameter other: the sequence being compared against
    func shiftBoundaries(against other: DiffFileData) {
        let endIndex = count
        var index = 0
        var otherIndex = 0
        var preceding = -1
        var otherPreceding = -1

        while true {
            // scan forwards to find beginning of another run of changes,
            // also keep track of the corresponding point in the other sequence
            while index < endIndex, !changedFlags[1 + index] {
                while true {
                    let isChanged = other.changedFlags[1 + otherIndex]

                    otherIndex += 1

                    if !isChanged {
                        break
                    }
                    // non-corresponding elements in the other sequence
                    // will count as the preceding batch of changes
                    otherPreceding = otherIndex
                }
                index += 1
            }

            if index == endIndex {
                break
            }
            var start = index
            let otherStart = otherIndex

            while true {
                // now find the end of this run of changes
                while index < endIndex, changedFlags[1 + index] {
                    index += 1
                }
                let end = index

                // if the first changed element matches the following unchanged one,
                // and this run does not follow right after a previous run,
                // and there are no elements deleted from the other sequence here,
                // then classify the first changed element as unchanged
                // and the following element as changed in its place

                // you might ask, how could this run follow right after another?
                // only because the previous run was shifted here
                guard end != endIndex,
                      equivalences[start] == equivalences[end],
                      !other.changedFlags[1 + otherIndex],
                      !((preceding >= 0 && start == preceding)
                          || (otherPreceding >= 0 && otherStart == otherPreceding))
                else {
                    break
                }

                changedFlags[1 + end] = true
                changedFlags[1 + start] = false
                start += 1
                index += 1
                // since one element-that-matches is now before this run instead of after,
                // we must advance in the other sequence to keep in synch
                otherIndex += 1
            }

            preceding = index
            otherPreceding = otherIndex
        }
    }

    /// marks a nondiscarded element as an insertion or a deletion
    func markChanged(virtualIndex: Int) {
        changedFlags[1 + realIndexes[virtualIndex]] = true
    }

    /// allocate a flag for each element, saying whether that element is an insertion
    /// or a deletion, with an extra always false element at each end of the vector
    private func clearChangedFlags() {
        changedFlags = Array(repeating: false, count: count + 2)
    }

    private func equivalenceCounts() -> [Int] {
        var counts = Array(repeating: 0, count: codeCount)

        for code in equivalences {
            counts[code] += 1
        }

        return counts
    }

    /// Mark to be discarded each element that matches no element of another sequence,
    /// if an element matches many elements mark it as provisionally discardable.
    /// - Parameter counts: the count of each equivalence code for the other sequence
    private func discardable(counts: [Int]) -> [Discard] {
        var discards = Array(repeating: Discard.keep, count: count)

        // multiply many by approximate square root of number of elements,
        // that is the threshold for provisionally discardable elements
        let many = Self.scaled(
            Self.manyMatches,
            bySquareRootOf: count / Self.matchScaleDivisor
        )

        for (index, code) in equivalences.enumerated() {
            let matches = counts[code]

            if matches == 0 {
                discards[index] = .discardable
            } else if matches > many {
                discards[index] = .provisional
            }
        }

        return discards
    }

    /// don't really discard the provisional elements except when they occur in a run
    /// of discardables, with nonprovisionals at the beginning and end
    private func filterDiscards(_ discards: inout [Discard]) {
        var index = 0

        while index < count {
            // cancel provisional discards not in middle of run of discards
            if discards[index] == .provisional {
                discards[index] = .keep
            } else if discards[index] != .keep {
                // we have found a nonprovisional discard
                index = filterRun(from: index, discards: &discards)
            }
            index += 1
        }
    }

    /// filters a single run of discardable elements
    /// - Returns: the last element index consumed by the run
    private func filterRun(from start: Int, discards: inout [Discard]) -> Int {
        var provisional = 0
        var runEnd = start

        // find end of this run of discardable elements,
        // count how many are provisionally discardable
        while runEnd < count, discards[runEnd] != .keep {
            if discards[runEnd] == .provisional {
                provisional += 1
            }
            runEnd += 1
        }

        // cancel provisional discards at end, and shrink the run
        while runEnd > start, discards[runEnd - 1] == .provisional {
            runEnd -= 1
            discards[runEnd] = .keep
            provisional -= 1
        }
        // now we have the length of a run of discardable elements
        // whose first and last are not provisional
        let length = runEnd - start

        // if 1/4 of the elements in the run are provisional,
        // cancel discarding of all provisional elements in the run
        if provisional * Self.provisionalRunDivisor > length {
            var index = runEnd

            while index > start {
                index -= 1

                if discards[index] == .provisional {
                    discards[index] = .keep
                }
            }

            return start
        }
        cancelProvisionalSubruns(from: start, length: length, discards: &discards)
        cancelProvisionalsAtRunEdges(from: start, length: length, discards: &discards)

        return start + length - 1
    }

    /// cancel any subrun of a minimum number of provisionals within the larger run
    private func cancelProvisionalSubruns(
        from start: Int,
        length: Int,
        discards: inout [Discard]
    ) {
        // minimum is approximate square root of length/4,
        // a subrun of two or more provisionals can stand when length is at least 16,
        // a subrun of 4 or more can stand when length is at least 64
        let minimum = Self.scaled(
            1,
            bySquareRootOf: length / Self.provisionalRunDivisor
        ) + 1

        var offset = 0
        var consecutive = 0

        while offset < length {
            if discards[start + offset] == .provisional {
                consecutive += 1

                if consecutive == minimum {
                    // back up to start of subrun, to cancel it all
                    offset -= consecutive
                } else if consecutive > minimum {
                    discards[start + offset] = .keep
                }
            } else {
                consecutive = 0
            }
            offset += 1
        }
    }

    /// scan from both ends of the run until 3 or more nonprovisionals in a row are found,
    /// or until the first nonprovisional at least 8 elements in, cancelling any provisional
    /// met until that point
    private func cancelProvisionalsAtRunEdges(
        from start: Int,
        length: Int,
        discards: inout [Discard]
    ) {
        cancelProvisionals(from: start, step: 1, length: length, discards: &discards)
        cancelProvisionals(from: start + length - 1, step: -1, length: length, discards: &discards)
    }

    private func cancelProvisionals(
        from origin: Int,
        step: Int,
        length: Int,
        discards: inout [Discard]
    ) {
        var consecutive = 0

        for offset in 0 ..< length {
            let index = origin + step * offset

            if offset >= Self.provisionalScanLimit, discards[index] == .discardable {
                break
            }

            if discards[index] == .provisional {
                consecutive = 0
                discards[index] = .keep
            } else if discards[index] == .keep {
                consecutive = 0
            } else {
                consecutive += 1
            }

            if consecutive == Self.nonProvisionalRunLength {
                break
            }
        }
    }

    /// actually discard the elements
    /// - Parameter discards: flags elements to be discarded
    private func discard(_ discards: [Discard]) {
        var virtualIndex = 0

        for index in 0 ..< count {
            if ignoresDiscards || discards[index] == .keep {
                undiscarded[virtualIndex] = equivalences[index]
                realIndexes[virtualIndex] = index
                virtualIndex += 1
            } else {
                changedFlags[1 + index] = true
            }
        }
        nonDiscardedCount = virtualIndex
    }

    /// doubles value once for every pair of bits of total, the approximate square root
    /// the original algorithm computes shifting total two bits at a time
    private static func scaled(_ value: Int, bySquareRootOf total: Int) -> Int {
        var result = value
        var remaining = total >> 2

        while remaining > 0 {
            result *= 2
            remaining >>= 2
        }

        return result
    }
}
