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
            preferences.compareLineEndings
        default:
            false
        }
    }

    func preferenceBox(_: PreferencesBox, setBool value: Bool, forKey key: CommonPrefs.Name) {
        switch key {
        case .compareLineEndings:
            preferences.compareLineEndings = value
        default:
            fatalError("key \(key) not handled")
        }
    }

    func preferenceBox(_: PreferencesBox, isEnabled _: CommonPrefs.Name) -> Bool {
        true
    }
}
