//
//  EndOfLine.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

enum EndOfLine: Int {
    case unix = 0
    // swiftlint:disable:next identifier_name
    case pc
}

extension EndOfLine {
    ///
    /// Detect the eol used inside text, only the first line is used to determine the type
    ///
    static func detectEOL(from text: String, defaultEOL: EndOfLine = .unix) -> EndOfLine {
        let wholeRange = text.startIndex ..< text.endIndex
        var eol = defaultEOL

        text.enumerateSubstrings(
            in: wholeRange,
            options: [.byLines, .substringNotRequired]
        ) { _, substringRange, _, stop in
            if substringRange.upperBound < wholeRange.upperBound {
                let ch = text[substringRange.upperBound]
                eol = (ch == "\r" || ch == "\r\n") ? .pc : .unix
            }
            stop = true
        }

        return eol
    }
}

extension EndOfLine: CustomStringConvertible {
    var stringValue: String {
        self == .unix ? "\n" : "\r\n"
    }

    var description: String {
        switch self {
        case .unix:
            "Unix (LF)"
        case .pc:
            "DOS (CR+LF)"
        }
    }
}
