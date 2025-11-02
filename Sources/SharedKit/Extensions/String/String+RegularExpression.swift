//
//  String+RegularExpression.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/05/12.
//  Copyright (c) 2012 visualdiffer.com
//

import Foundation

private struct GlobConverter {
    private var regex = [NSRegularExpression]()
    private var templates = [String]()

    init() {
        let globs = [
            ("([.^$+(){}\\[\\]\\\\|])", "\\\\$1"),
            ("\\?", "(.|[\r\n])"),
            ("\\*", "(.|[\r\n])*"),
        ]

        for (regexString, templateString) in globs {
            // swiftlint:disable:next force_try
            let re = try! NSRegularExpression(
                pattern: regexString,
                options: .caseInsensitive
            )
            regex.append(re)
            templates.append(templateString)
        }
    }

    private func replace(index: Int, in str: String) -> String {
        let re = regex[index]
        let template = templates[index]

        return re.stringByReplacingMatches(
            in: str,
            options: [],
            range: NSRange(location: 0, length: str.count),
            withTemplate: template
        )
    }

    func convert(_ str: String) -> String {
        var re = str

        for i in 0 ..< regex.count {
            re = replace(index: i, in: re)
        }
        return re
    }
}

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
                    while i < size, let num = chars[position].wholeNumberValue {
                        value = value * 10 + num
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

    /**
      * Convert a glob string to a valid regular expression string
      * Strings like "*m" are converted to ".*m"
      * Brackets and "?" are correctly escaped
     */
    private func _convertGlobMetaCharsToRegexpMetaChars() -> String {
        enum Static {
            static let converter: GlobConverter = .init()
        }

        return Static.converter.convert(self)
    }

    func convertGlobMetaCharsToRegexpMetaChars() -> String {
        _convertGlobMetaCharsToRegexpMetaChars()
    }
}
