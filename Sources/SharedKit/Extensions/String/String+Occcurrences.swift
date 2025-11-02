//
//  String+Occcurrences.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/05/12.
//  Copyright (c) 2012 visualdiffer.com
//

extension String {
    // periphery:ignore
    func countOccurrences(
        _ pattern: String,
        options: NSString.CompareOptions = []
    ) -> Int {
        var count = 0
        var remainingRange = startIndex ..< endIndex

        while let foundRange = range(
            of: pattern,
            options: options,
            range: remainingRange
        ) {
            count += 1
            remainingRange = foundRange.upperBound ..< endIndex
        }

        return count
    }

    func rangesOfString(
        _ pattern: String,
        options: NSString.CompareOptions
    ) -> [Range<String.Index>] {
        var ranges = [Range<String.Index>]()
        var remainingRange = startIndex ..< endIndex

        while let foundRange = range(
            of: pattern,
            options: options,
            range: remainingRange
        ) {
            ranges.append(foundRange)
            remainingRange = foundRange.upperBound ..< endIndex
        }

        return ranges
    }
}
