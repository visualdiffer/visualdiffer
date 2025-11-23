//
//  EndOfLine.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

enum EndOfLine: Int {
    case unix
    case pcCR
    case pcCRLF
    case missing
    case mixed

    static func from(character ch: Character) -> EndOfLine {
        switch ch {
        case "\r":
            .pcCR
        case "\r\n":
            .pcCRLF
        case "\n":
            .unix
        default:
            .missing
        }
    }
}

extension EndOfLine: CustomStringConvertible {
    var stringValue: String {
        switch self {
        case .unix:
            "\n"
        case .pcCR:
            "\r"
        case .pcCRLF:
            "\r\n"
        case .missing:
            ""
        case .mixed:
            ""
        }
    }

    var description: String {
        switch self {
        case .unix:
            "Unix (LF)"
        case .pcCR:
            "DOS (CR)"
        case .pcCRLF:
            "DOS (CR+LF)"
        case .missing:
            "None"
        case .mixed:
            "MIXED"
        }
    }

    var visibleSymbol: String {
        switch self {
        case .unix:
            "\u{00B6}"
        case .pcCR, .pcCRLF:
            "\u{00A4}"
        default:
            ""
        }
    }
}
