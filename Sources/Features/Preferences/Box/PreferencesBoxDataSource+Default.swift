//
//  PreferencesBoxDataSource+Default.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension PreferencesBoxDataSource {
    func preferenceBox(_: PreferencesBox, boolForKey key: CommonPrefs.Name) -> Bool {
        fatalError("key \(key) not handled")
    }

    func preferenceBox(_: PreferencesBox, setBool _: Bool, forKey key: CommonPrefs.Name) {
        fatalError("key \(key) not handled")
    }

    func preferenceBox(_: PreferencesBox, integerForKey key: CommonPrefs.Name) -> Int {
        fatalError("key \(key) not handled")
    }

    func preferenceBox(_: PreferencesBox, setInteger _: Int, forKey key: CommonPrefs.Name) {
        fatalError("key \(key) not handled")
    }

    func preferenceBox(_: PreferencesBox, stringForKey key: CommonPrefs.Name) -> String? {
        fatalError("key \(key) not handled")
    }

    func preferenceBox(_: PreferencesBox, setString _: String?, forKey key: CommonPrefs.Name) {
        fatalError("key \(key) not handled")
    }

    func preferenceBox(_: PreferencesBox, objectForKey key: CommonPrefs.Name) -> Any? {
        fatalError("key \(key) not handled")
    }

    func preferenceBox(_: PreferencesBox, setObject _: Any?, forKey key: CommonPrefs.Name) {
        fatalError("key \(key) not handled")
    }

    func preferenceBox(_: PreferencesBox, isEnabled key: CommonPrefs.Name) -> Bool {
        fatalError("key \(key) not handled")
    }
}
