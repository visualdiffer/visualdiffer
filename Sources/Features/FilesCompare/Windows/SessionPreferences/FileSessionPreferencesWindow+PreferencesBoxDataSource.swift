//
//  FileSessionPreferencesWindow+PreferencesBoxDataSource.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FileSessionPreferencesWindow: @preconcurrency PreferencesBoxDataSource {
    func preferenceBox(_: PreferencesBox, boolForKey key: CommonPrefs.Name) -> Bool {
        switch key {
        case .compareLineEndings:
            preferences.diffResultOptions.contains(.compareLineEndings)
        case .ignoreLeadingWhitespaces:
            preferences.diffResultOptions.contains(.ignoreLeadingWhitespaces)
        case .ignoreTrailingWhitespaces:
            preferences.diffResultOptions.contains(.ignoreTrailingWhitespaces)
        case .ignoreInternalWhitespaces:
            preferences.diffResultOptions.contains(.ignoreInternalWhitespaces)
        default:
            false
        }
    }

    func preferenceBox(_: PreferencesBox, setBool value: Bool, forKey key: CommonPrefs.Name) {
        switch key {
        case .compareLineEndings:
            preferences.diffResultOptions.setValue(value, element: .compareLineEndings)
        case .ignoreLeadingWhitespaces:
            preferences.diffResultOptions.setValue(value, element: .ignoreLeadingWhitespaces)
        case .ignoreTrailingWhitespaces:
            preferences.diffResultOptions.setValue(value, element: .ignoreTrailingWhitespaces)
        case .ignoreInternalWhitespaces:
            preferences.diffResultOptions.setValue(value, element: .ignoreInternalWhitespaces)
        default:
            fatalError("key \(key) not handled")
        }
    }

    func preferenceBox(_: PreferencesBox, isEnabled _: CommonPrefs.Name) -> Bool {
        true
    }
}
