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

struct AlignRuleMatch {
    let replacedName: String
    let templateOptions: AlignTemplateOptions

    func matches(
        rightName: String
    ) -> Bool {
        rightName.hasPrefix(
            replacedName,
            ignoreCase: templateOptions.contains(.caseInsensitive)
        )
    }
}

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

    /// create a match for the left string using this rule
    /// - parameter leftName: the left string
    /// - returns: the match if the left string matches the regular expression
    func match(
        leftName: String
    ) -> AlignRuleMatch? {
        guard let result = regExp.regularExpression()?.firstMatch(
            in: leftName,
            options: [],
            range: NSRange(location: 0, length: leftName.utf16.count)
        ) else {
            return nil
        }

        let replacedName = leftName.replace(
            template: template.pattern,
            result: result
        )
        // an empty replacement would prefix-match every right name
        guard !replacedName.isEmpty else {
            return nil
        }

        return AlignRuleMatch(
            replacedName: replacedName,
            templateOptions: template.options
        )
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
