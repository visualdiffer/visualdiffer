//
//  FindOptions.swift
//  VisualDiffer
//
//  Created by davide ficano on 22/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

enum FindMode: Int, CaseIterable {
    case containingText = 1
    case matchingWord
    case regularExpression

    var title: String {
        switch self {
        case .containingText:
            NSLocalizedString("Containing Text", comment: "")
        case .matchingWord:
            NSLocalizedString("Matching Word", comment: "")
        case .regularExpression:
            NSLocalizedString("Regular Expression", comment: "")
        }
    }
}

struct FindOptions {
    var mode = FindMode.containingText
    var matchCase = false
    var matchFiles = true
    var matchFolders = true

    // nil when the pattern is not a valid regular expression
    func matcher(for pattern: String) -> ((String) -> Bool)? {
        if mode == .containingText {
            // the string search also matches canonically equivalent forms, e.g. composed and decomposed accents
            let compareOptions: String.CompareOptions = matchCase ? [] : .caseInsensitive

            return { $0.range(of: pattern, options: compareOptions) != nil }
        }

        // the regular expression compares code units, both sides are precomposed
        // so that a decomposed file name matches a composed pattern
        guard let re = regex(for: pattern.precomposedStringWithCanonicalMapping) else {
            return nil
        }

        return { text in
            let text = text.precomposedStringWithCanonicalMapping

            return re.firstMatch(
                in: text,
                options: [],
                range: NSRange(location: 0, length: text.utf16.count)
            ) != nil
        }
    }

    private func regex(for pattern: String) -> NSRegularExpression? {
        let expression = switch mode {
        case .matchingWord:
            // \b matches the word boundaries around the searched text
            "\\b\(NSRegularExpression.escapedPattern(for: pattern))\\b"
        // .containingText is matched without a regular expression, it never reaches here
        case .containingText, .regularExpression:
            pattern
        }

        return try? NSRegularExpression(
            pattern: expression,
            options: matchCase ? [] : .caseInsensitive
        )
    }
}
