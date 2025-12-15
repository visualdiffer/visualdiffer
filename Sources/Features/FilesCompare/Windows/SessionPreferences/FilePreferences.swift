//
//  FilePreferences.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

struct FilePreferences {
    var diffResultOptions: DiffResult.Options = []
}

extension FilePreferences {
    mutating func fromUserDefaults() {
        let options: [(CommonPrefs.Name, DiffResult.Options)] = [
            (.ignoreLineEndings, .ignoreLineEndings),
            (.ignoreLeadingWhitespaces, .ignoreLeadingWhitespaces),
            (.ignoreTrailingWhitespaces, .ignoreTrailingWhitespaces),
            (.ignoreInternalWhitespaces, .ignoreInternalWhitespaces),
        ]

        for (prefName, option) in options {
            diffResultOptions.setValue(CommonPrefs.shared.bool(forKey: prefName), element: option)
        }
    }
}

extension CommonPrefs.Name {
    static let ignoreLineEndings = CommonPrefs.Name(rawValue: "ignoreLineEndings")
    static let ignoreLeadingWhitespaces = CommonPrefs.Name(rawValue: "ignoreLeadingWhitespaces")
    static let ignoreTrailingWhitespaces = CommonPrefs.Name(rawValue: "ignoreTrailingWhitespaces")
    static let ignoreInternalWhitespaces = CommonPrefs.Name(rawValue: "ignoreInternalWhitespaces")
}
