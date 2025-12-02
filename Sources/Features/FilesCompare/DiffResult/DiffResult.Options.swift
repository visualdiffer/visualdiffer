//
//  DiffResult.Options.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/12/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension DiffResult.Options {
    static let allIgnoreWhitespaces: Self = [
        .ignoreLeadingWhitespaces,
        .ignoreTrailingWhitespaces,
        .ignoreInternalWhitespaces,
    ]

    func stripWhitespaces(text: String) -> String {
        if intersection(.allIgnoreWhitespaces).isEmpty {
            return text
        }
        var isLeading = true
        var whitespaceStart = -1
        var whitespaceCount = 0

        var stripped = String()
        stripped.reserveCapacity(text.count)

        for (offset, ch) in text.enumerated() {
            if ch.isWhitespace {
                if isLeading {
                    if !contains(.ignoreLeadingWhitespaces) {
                        stripped.append(ch)
                    }
                } else {
                    if whitespaceStart == -1 {
                        whitespaceStart = offset
                    }
                    whitespaceCount += 1
                }
            } else {
                isLeading = false

                if whitespaceCount > 0, !contains(.ignoreInternalWhitespaces) {
                    let start = text.index(text.startIndex, offsetBy: whitespaceStart)
                    let end = text.index(start, offsetBy: whitespaceCount)
                    stripped.append(contentsOf: text[start ..< end])
                }

                whitespaceStart = -1
                whitespaceCount = 0
                stripped.append(ch)
            }
        }

        if whitespaceCount > 0, !contains(.ignoreTrailingWhitespaces) {
            let start = text.index(text.startIndex, offsetBy: whitespaceStart)
            let end = text.index(start, offsetBy: whitespaceCount)
            stripped.append(contentsOf: text[start ..< end])
        }

        return stripped
    }

    func applyTransformations(component: DiffLineComponent) -> String {
        let stripped = stripWhitespaces(text: component.text)

        if contains(.compareLineEndings) {
            return stripped + component.eol.stringValue
        }
        return stripped
    }
}
