//
//  String+RegularExpression.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/05/12.
//  Copyright (c) 2012 visualdiffer.com
//

import Foundation

public extension String {
    /**
     * Replace tagged expressions ($1, $2, ...) present in template
     * with substrings ranges present in result
     * Example: self = 001.jpg template = $1.raw returns 001.raw
     */
    func replace(
        template chars: String,
        result: NSTextCheckingResult
    ) -> String {
        let size = chars.count
        var foundTagged = false
        var foundEscape = false
        var i = 0

        var inString = ""

        while i < size {
            if foundTagged {
                foundTagged = false
                var value = 0
                var position = chars.index(chars.startIndex, offsetBy: i)

                if chars[position] == "$" {
                    inString.append(chars[position])
                    i += 1
                } else {
                    let maxSupportedCaptureGroupIndex = 100
                    while i < size, let num = chars[position].wholeNumberValue {
                        if value < maxSupportedCaptureGroupIndex {
                            value = value * 10 + num
                        }
                        i += 1
                        position = chars.index(chars.startIndex, offsetBy: i)
                    }
                    if value < result.numberOfRanges, let range = Range(result.range(at: value), in: self) {
                        inString.append(String(self[range]))
                    }
                }
            } else if foundEscape {
                foundEscape = false
                let position = chars.index(chars.startIndex, offsetBy: i)
                i += 1
                switch chars[position] {
                case "t":
                    inString.append("\t")
                case "\\":
                    inString.append("\\")
                default:
                    break
                }
            }
            // should exceed array range
            if i < size {
                let position = chars.index(chars.startIndex, offsetBy: i)
                i += 1
                let ch = chars[position]

                if ch == "$" {
                    foundTagged = true
                } else if ch == "\\" {
                    foundEscape = true
                } else {
                    inString.append(ch)
                }
            }
        }
        return inString
    }
}
