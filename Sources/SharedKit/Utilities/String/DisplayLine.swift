//
//  DisplayLine.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

/// text of a line as it gets drawn, together with the mapping needed to translate
/// the character offsets of the source text into offsets of the drawn text
///
/// Tab expansion changes the length of a line, so an offset in the source text does
/// not match the same offset in the drawn one. Everything else is replaced one
/// character at a time, therefore a line without tabs needs no mapping at all.
struct DisplayLine {
    let text: String

    // one entry per source character, plus the past the end offset,
    // empty when the drawn text matches the source text character by character
    let offsets: [Int]

    func displayOffset(for sourceOffset: Int) -> Int {
        if offsets.isEmpty {
            return sourceOffset
        }

        return sourceOffset < offsets.count ? offsets[sourceOffset] : text.count
    }
}
