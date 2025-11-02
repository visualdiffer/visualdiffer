//
//  PreferencesBoxDataSource.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

protocol PreferencesBoxDataSource {
    func preferenceBox(
        _ preferencesBox: PreferencesBox,
        boolForKey key: CommonPrefs.Name
    ) -> Bool
    func preferenceBox(
        _ preferencesBox: PreferencesBox,
        setBool value: Bool,
        forKey key: CommonPrefs.Name
    )

    func preferenceBox(
        _ preferencesBox: PreferencesBox,
        integerForKey key: CommonPrefs.Name
    ) -> Int
    func preferenceBox(
        _ preferencesBox: PreferencesBox,
        setInteger value: Int,
        forKey key: CommonPrefs.Name
    )

    func preferenceBox(
        _ preferencesBox: PreferencesBox,
        stringForKey key: CommonPrefs.Name
    ) -> String?
    func preferenceBox(
        _ preferencesBox: PreferencesBox,
        setString value: String?,
        forKey key: CommonPrefs.Name
    )

    func preferenceBox(
        _ preferencesBox: PreferencesBox,
        objectForKey key: CommonPrefs.Name
    ) -> Any?
    func preferenceBox(
        _ preferencesBox: PreferencesBox,
        setObject value: Any?,
        forKey key: CommonPrefs.Name
    )

    func preferenceBox(_ preferencesBox: PreferencesBox, isEnabled key: CommonPrefs.Name) -> Bool
}
