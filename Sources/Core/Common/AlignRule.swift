//
//  AlignRule.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

import os

struct AlignTemplateOptions: OptionSet {
    let rawValue: UInt

    static let caseInsensitive = AlignTemplateOptions(rawValue: 1 << 0)
}

typealias AlignRegExp = AlignRule.Pair<NSRegularExpression.Options>
typealias AlignTemplate = AlignRule.Pair<AlignTemplateOptions>

public struct AlignRule {
    struct Pair<T> {
        let pattern: String
        let options: T
    }

    enum Key: String {
        case regExp = "leftExpression"
        case template = "rightExpression"
        case regExpOptions = "leftOptions"
        case templateOptions = "rightOptions"
    }

    let regExp: AlignRegExp
    let template: AlignTemplate

    init(
        regExp: AlignRegExp,
        template: AlignTemplate
    ) {
        self.regExp = regExp
        self.template = template
    }

    init?(_ dictionary: [String: Any]) {
        guard let regExp = AlignRegExp(dictionary),
              let template = AlignTemplate(dictionary) else {
            return nil
        }

        self.init(regExp: regExp, template: template)
    }
}

extension AlignRule {
    func toDictionary() -> [String: Any] {
        [
            Key.regExp.rawValue: regExp.pattern,
            Key.regExpOptions.rawValue: regExp.options.rawValue,
            Key.template.rawValue: template.pattern,
            Key.templateOptions.rawValue: template.options.rawValue,
        ]
    }

    /// Check if the `lhs` string matches the `rhs` using this rule
    /// - lhs: the left string
    /// - rhs: the right string
    /// - Returns: `true` if the strings match,`false` otherwise
    func matches(
        name lhs: String,
        with rhs: String
    ) -> Bool {
        guard let result = regExp.regularExpression()?.firstMatch(
            in: lhs,
            options: [],
            range: NSRange(location: 0, length: lhs.utf16.count)
        ) else {
            return false
        }

        let replaced = lhs.replace(
            template: template.pattern,
            result: result
        )
        if template.options.contains(.caseInsensitive) {
            return rhs.hasPrefix(replaced, ignoreCase: true)
        }
        return rhs.hasPrefix(replaced)
    }
}

extension AlignRule.Pair where T == NSRegularExpression.Options {
    private static let cachedRegExpressions = OSAllocatedUnfairLock(
        initialState: [String: NSRegularExpression]()
    )

    init() {
        self.init(pattern: "", options: [])
    }

    init?(_ dictionary: [String: Any]) {
        guard let pattern = dictionary[AlignRule.Key.regExp.rawValue] as? String else {
            return nil
        }

        let options = if let rawValue = dictionary[AlignRule.Key.regExpOptions.rawValue] as? UInt {
            NSRegularExpression.Options(rawValue: rawValue)
        } else {
            dictionary[AlignRule.Key.regExpOptions.rawValue] as? NSRegularExpression.Options ?? []
        }

        self.init(
            pattern: pattern,
            options: options
        )
    }

    func regularExpression() -> NSRegularExpression? {
        let pattern = pattern
        let options = options
        let key = "\(pattern)|\(options.rawValue)"

        return Self.cachedRegExpressions.withLock { values in
            if let value = values[key] {
                return value
            }

            guard let value = try? NSRegularExpression(
                pattern: pattern,
                options: options
            ) else {
                return nil
            }

            values[key] = value

            return value
        }
    }
}

extension AlignRule.Pair where T == AlignTemplateOptions {
    init() {
        self.init(pattern: "", options: [])
    }

    init?(_ dictionary: [String: Any]) {
        guard let pattern = dictionary[AlignRule.Key.template.rawValue] as? String else {
            return nil
        }

        let options = if let rawValue = dictionary[AlignRule.Key.templateOptions.rawValue] as? UInt {
            AlignTemplateOptions(rawValue: rawValue)
        } else {
            dictionary[AlignRule.Key.templateOptions.rawValue] as? AlignTemplateOptions ?? []
        }

        self.init(
            pattern: pattern,
            options: options
        )
    }
}
