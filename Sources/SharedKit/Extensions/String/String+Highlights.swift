//
//  String+Highlights.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/13.
//  Copyright (c) 2013 visualdiffer.com
//

extension String {
    func highlights(
        _ ranges: [Range<Self.Index>],
        normalStyle: [NSAttributedString.Key: Any],
        highlightStyle: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        if ranges.isEmpty {
            return NSAttributedString(string: self, attributes: normalStyle)
        }
        let attrString = NSMutableAttributedString(string: self)

        attrString.beginEditing()
        var start = startIndex

        for range in ranges {
            let normalRange = NSRange(start ..< range.lowerBound, in: self)
            let highlightRange = NSRange(range, in: self)
            attrString.addAttributes(highlightStyle, range: highlightRange)
            attrString.addAttributes(normalStyle, range: normalRange)

            start = range.upperBound
        }
        let remainingRange = start ..< endIndex
        attrString.addAttributes(normalStyle, range: NSRange(remainingRange, in: self))
        attrString.endEditing()

        return attrString
    }

    func highlights(
        _ ranges: [Range<Self.Index>],
        normalColor: NSColor,
        highlightColor: NSColor,
        font: NSFont
    ) -> NSAttributedString {
        let normalStyle = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: normalColor,
        ]

        let boldFont = NSFontManager.shared.convert(font, toHaveTrait: [.boldFontMask, .unitalicFontMask])
        let hightlightStyle = [
            NSAttributedString.Key.font: boldFont,
            NSAttributedString.Key.foregroundColor: highlightColor,
        ]

        return highlights(
            ranges,
            normalStyle: normalStyle,
            highlightStyle: hightlightStyle
        )
    }

    // the offsets must be ascending and non overlapping, the string is walked once,
    // the offsets starting past the end are dropped and the others are clamped
    func characterRanges(from offsets: [Range<Int>]) -> [Range<Self.Index>] {
        let length = count
        var ranges = [Range<Self.Index>]()
        var start = startIndex
        var startOffset = 0

        for offsetRange in offsets where offsetRange.lowerBound < length {
            let clampedUpper = min(offsetRange.upperBound, length)
            let lower = index(start, offsetBy: offsetRange.lowerBound - startOffset)
            let upper = index(lower, offsetBy: clampedUpper - offsetRange.lowerBound)

            ranges.append(lower ..< upper)

            start = upper
            startOffset = clampedUpper
        }

        return ranges
    }
}
