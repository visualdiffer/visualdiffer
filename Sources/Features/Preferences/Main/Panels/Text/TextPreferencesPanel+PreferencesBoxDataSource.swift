//
//  TextPreferencesPanel+PreferencesBoxDataSource.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension TextPreferencesPanel: @preconcurrency PreferencesBoxDataSource {
    func preferenceBox(_: PreferencesBox, boolForKey key: CommonPrefs.Name) -> Bool {
        switch key {
        case .ignoreLineEndings,
             .ignoreLeadingWhitespaces,
             .ignoreTrailingWhitespaces,
             .ignoreInternalWhitespaces,
             .ignoreCharacterCase:
            CommonPrefs.shared.bool(forKey: key)
        default:
            fatalError("key \(key) not handled")
        }
    }

    func preferenceBox(_: PreferencesBox, setBool value: Bool, forKey key: CommonPrefs.Name) {
        switch key {
        case .ignoreLineEndings,
             .ignoreLeadingWhitespaces,
             .ignoreTrailingWhitespaces,
             .ignoreInternalWhitespaces,
             .ignoreCharacterCase:
            CommonPrefs.shared.set(value, forKey: key)
        default:
            fatalError("key \(key) not handled")
        }
    }

    func preferenceBox(_: PreferencesBox, isEnabled _: CommonPrefs.Name) -> Bool {
        true
    }
}
