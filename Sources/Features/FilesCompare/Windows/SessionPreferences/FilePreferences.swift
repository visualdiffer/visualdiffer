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
    var compareLineEndings: Bool {
        get {
            diffResultOptions.contains(.compareLineEndings)
        }

        set {
            if newValue {
                diffResultOptions.insert(.compareLineEndings)
            } else {
                diffResultOptions.remove(.compareLineEndings)
            }
        }
    }
}

extension CommonPrefs.Name {
    static let compareLineEndings = CommonPrefs.Name(rawValue: "compareLineEndings")
}
