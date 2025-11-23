//
//  DiffLineComponent.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

struct DiffLineComponent {
    let text: String
    let eol: EndOfLine

    static func splitLines(_ text: String) -> [DiffLineComponent] {
        var lines: [DiffLineComponent] = []

        Self.enumerateLines(text: text) {
            lines.append($0)
        }

        return lines
    }

    static func enumerateLines(text: String, _ callback: @escaping (_ component: DiffLineComponent) -> Void) {
        text.enumerateSubstrings(
            in: text.startIndex ..< text.endIndex,
            options: [.byLines]
        ) { substring, substringRange, _, _ in
            if let substring {
                let eol = eol(from: text, substringRange: substringRange)
                callback(DiffLineComponent(text: substring, eol: eol))
            }
        }
    }

    private static func eol(from text: String, substringRange: Range<String.Index>) -> EndOfLine {
        let wholeRange = text.startIndex ..< text.endIndex

        guard substringRange.upperBound < wholeRange.upperBound else {
            return .missing
        }
        return EndOfLine.from(character: text[substringRange.upperBound])
    }
}

extension DiffLineComponent {
    var withEol: String {
        text + eol.stringValue
    }
}

extension [DiffLineComponent] {
    func detectEOL() -> EndOfLine {
        guard let firstEol = first?.eol else {
            return .missing
        }

        return dropFirst().contains { $0.eol != .missing && $0.eol != firstEol }
            ? .mixed
            : firstEol
    }
}
