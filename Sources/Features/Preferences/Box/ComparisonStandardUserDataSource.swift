//
//  ComparisonStandardUserDataSource.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class ComparisonStandardUserDataSource: StandardUserPreferencesBoxDataSource {
    override func preferenceBox(
        _ preferencesBox: PreferencesBox,
        boolForKey key: CommonPrefs.Name
    ) -> Bool {
        switch key {
        case .virtualResourceFork:
            CommonPrefs.shared.checkResourceForks
        case .virtualFinderLabel:
            CommonPrefs.shared.finderLabel
        case .virtualFinderTags:
            CommonPrefs.shared.finderTags
        default:
            super.preferenceBox(preferencesBox, boolForKey: key)
        }
    }

    override func preferenceBox(
        _ preferencesBox: PreferencesBox,
        setBool value: Bool,
        forKey key: CommonPrefs.Name
    ) {
        switch key {
        case .virtualResourceFork:
            CommonPrefs.shared.checkResourceForks = value
        case .virtualFinderLabel:
            CommonPrefs.shared.finderLabel = value
        case .virtualFinderTags:
            CommonPrefs.shared.finderTags = value
        default:
            super.preferenceBox(preferencesBox, setBool: value, forKey: key)
        }
    }

    override func preferenceBox(
        _ preferencesBox: PreferencesBox,
        integerForKey key: CommonPrefs.Name
    ) -> Int {
        switch key {
        case .virtualComparatorWithoutMethod:
            CommonPrefs.shared.comparatorWithoutMethod.rawValue
        case .virtualDisplayFiltersWithoutMethod:
            CommonPrefs.shared.displayFiltersWithoutMethod.rawValue
        default:
            super.preferenceBox(preferencesBox, integerForKey: key)
        }
    }

    override func preferenceBox(
        _ preferencesBox: PreferencesBox,
        setInteger value: Int,
        forKey key: CommonPrefs.Name
    ) {
        switch key {
        case .virtualComparatorWithoutMethod:
            CommonPrefs.shared.comparatorWithoutMethod = ComparatorOptions(rawValue: value)
        case .virtualDisplayFiltersWithoutMethod:
            CommonPrefs.shared.displayFiltersWithoutMethod = DisplayOptions(rawValue: value)
        default:
            super.preferenceBox(preferencesBox, setInteger: value, forKey: key)
        }
    }

    override func preferenceBox(_ preferencesBox: PreferencesBox, isEnabled key: CommonPrefs.Name) -> Bool {
        switch key {
        case .virtualFinderLabel:
            preferenceBox(preferencesBox, boolForKey: .virtualFinderTags) == false
        case .virtualFinderTags:
            preferenceBox(preferencesBox, boolForKey: .virtualFinderLabel) == false
        default:
            true
        }
    }
}
