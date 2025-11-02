//
//  StandardUserPreferencesBoxDataSource.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class StandardUserPreferencesBoxDataSource: NSObject, PreferencesBoxDataSource {
    func preferenceBox(
        _: PreferencesBox,
        boolForKey key: CommonPrefs.Name
    ) -> Bool {
        CommonPrefs.shared.bool(forKey: key)
    }

    func preferenceBox(
        _: PreferencesBox,
        setBool value: Bool,
        forKey key: CommonPrefs.Name
    ) {
        CommonPrefs.shared.set(value, forKey: key)
    }

    func preferenceBox(
        _: PreferencesBox,
        integerForKey key: CommonPrefs.Name
    ) -> Int {
        CommonPrefs.shared.integer(forKey: key)
    }

    func preferenceBox(
        _: PreferencesBox,
        setInteger value: Int,
        forKey key: CommonPrefs.Name
    ) {
        CommonPrefs.shared.set(value, forKey: key)
    }

    func preferenceBox(_: PreferencesBox, stringForKey _: CommonPrefs.Name) -> String? {
        fatalError("Not implemented")
    }

    func preferenceBox(_: PreferencesBox, setString _: String?, forKey _: CommonPrefs.Name) {
        fatalError("Not implemented")
    }

    func preferenceBox(_: PreferencesBox, objectForKey _: CommonPrefs.Name) -> Any? {
        fatalError("Not implemented")
    }

    func preferenceBox(_: PreferencesBox, setObject _: Any?, forKey _: CommonPrefs.Name) {
        fatalError("Not implemented")
    }

    func preferenceBox(_: PreferencesBox, isEnabled _: CommonPrefs.Name) -> Bool {
        true
    }
}
