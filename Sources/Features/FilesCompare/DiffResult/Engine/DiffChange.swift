//
//  DiffChange.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

/// one place where some elements are deleted and some are inserted
///
/// `line0` and `line1` are the first affected elements in the two sequences (origin 0),
/// `deleted` is the number of elements removed from the left sequence and `inserted`
/// the number of elements added from the right one.
/// When `deleted` is 0 then `line0` is the element before which the insertion was done,
/// and vice versa for `inserted` and `line1`.
struct DiffChange: Equatable {
    let line0: Int
    let line1: Int
    let deleted: Int
    let inserted: Int
}

extension DiffChange: CustomStringConvertible {
    var description: String {
        "\(line0 + 1), \(line1 + 1) inserted \(inserted), deleted \(deleted)"
    }
}
