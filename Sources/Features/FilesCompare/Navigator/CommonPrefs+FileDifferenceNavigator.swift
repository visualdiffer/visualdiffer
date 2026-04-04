//
//  CommonPrefs+FileDifferenceNavigator.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/02/21.
//  Copyright (c) 2021 visualdiffer.com
//

extension CommonPrefs.Name {
    enum FileNavigator {
        static let wrapsAroundDifferences = CommonPrefs.Name(rawValue: "fileWrapsAroundDifferences")
        static let autoAdvanceWhenNoMoreDifferences = CommonPrefs.Name(rawValue: "fileAutoAdvanceWhenNoMoreDifferences")
    }
}

extension CommonPrefs {
    var fileWrapsAroundDifferences: Bool {
        bool(forKey: .FileNavigator.wrapsAroundDifferences)
    }

    var fileAutoAdvanceWhenNoMoreDifferences: Bool {
        bool(forKey: .FileNavigator.autoAdvanceWhenNoMoreDifferences)
    }
}
