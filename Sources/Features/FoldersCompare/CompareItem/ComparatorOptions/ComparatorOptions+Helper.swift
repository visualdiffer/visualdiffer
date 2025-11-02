//
//  ComparatorOptions+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 02/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

public extension ComparatorOptions {
    init(number: NSNumber?) {
        self.init(rawValue: number?.intValue ?? 0)
    }

    func toNumber() -> NSNumber {
        NSNumber(value: rawValue)
    }
}

public extension ComparatorOptions {
    var onlyMethodFlags: Self {
        intersection(.typeMask)
    }

    var withoutMethodFlags: Self {
        subtracting(.typeMask)
    }

    var onlyAlignFlags: Self {
        intersection(.alignMask)
    }

    var withoutAlignFlags: Self {
        subtracting(.alignMask)
    }

    func changeWithoutMethod(_ flags: Self) -> Self {
        withoutMethodFlags.union(flags)
    }

    func changeWithoutMethod(_ flags: Int) -> Self {
        withoutMethodFlags.union(.init(rawValue: flags))
    }

    func changeAlign(_ newValue: Self) -> Self {
        guard newValue.isSubset(of: .alignMask) else {
            fatalError("Invalid options: \(newValue)")
        }

        var changed = withoutAlignFlags
        changed.insert(newValue)
        return changed
    }

    func changeAlign(_ newValue: Int) -> Self {
        changeAlign(.init(rawValue: newValue))
    }

    var hasFinderLabel: Bool {
        contains(.finderLabel)
    }

    // remove tags flag because is mutually exclusive with label flag
    func changeFinderLabel(_ isOn: Bool) -> Self {
        if isOn {
            subtracting(.finderTags).union(.finderLabel)
        } else {
            subtracting(.finderTags).subtracting(.finderLabel)
        }
    }

    var hasFinderTags: Bool {
        contains(.finderTags)
    }

    // remove label flag because is mutually exclusive with tag flag
    func changeFinderTags(_ isOn: Bool) -> Self {
        if isOn {
            subtracting(.finderLabel).union(.finderTags)
        } else {
            subtracting(.finderLabel).subtracting(.finderTags)
        }
    }
}
