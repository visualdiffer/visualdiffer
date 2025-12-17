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
    mutating func from(sessionDiff: SessionDiff) {
        diffResultOptions = sessionDiff.extraData.diffResultOptions
    }
}

extension CommonPrefs.Name {
    static let ignoreLineEndings = CommonPrefs.Name(rawValue: "ignoreLineEndings")
    static let ignoreLeadingWhitespaces = CommonPrefs.Name(rawValue: "ignoreLeadingWhitespaces")
    static let ignoreTrailingWhitespaces = CommonPrefs.Name(rawValue: "ignoreTrailingWhitespaces")
    static let ignoreInternalWhitespaces = CommonPrefs.Name(rawValue: "ignoreInternalWhitespaces")
}
