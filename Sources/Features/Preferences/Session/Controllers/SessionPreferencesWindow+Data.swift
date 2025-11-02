//
//  SessionPreferencesWindow+Data.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension SessionPreferencesWindow {
    struct Data {
        var comparatorOptions: ComparatorOptions
        var displayOptions: DisplayOptions
        var followSymLinks: Bool
        var skipPackages: Bool
        var traverseFilteredFolders: Bool
        var timestampToleranceSeconds: Int
        var expandAllFolders: Bool
        var fileExtraOptions: FileExtraOptions
        var fileFilters: String?
        var alignFlags: ComparatorOptions
        var alignRules: [AlignRule]

        init() {
            comparatorOptions = []
            displayOptions = []
            followSymLinks = false
            skipPackages = false
            traverseFilteredFolders = false
            timestampToleranceSeconds = 0
            expandAllFolders = false
            fileExtraOptions = []
            fileFilters = nil
            alignFlags = []
            alignRules = [AlignRule]()
        }
    }
}

extension SessionPreferencesWindow.Data {
    func updateSessionDiff(_ sessionDiff: SessionDiff) {
        sessionDiff.comparatorOptions = comparatorOptions
        sessionDiff.displayOptions = displayOptions
        sessionDiff.followSymLinks = followSymLinks
        sessionDiff.timestampToleranceSeconds = Double(timestampToleranceSeconds)
        sessionDiff.exclusionFileFilters = fileFilters
        sessionDiff.skipPackages = skipPackages
        sessionDiff.fileExtraOptions = fileExtraOptions
        sessionDiff.traverseFilteredFolders = traverseFilteredFolders
        sessionDiff.fileNameAlignments = alignRules
        sessionDiff.expandAllFolders = expandAllFolders
    }

    static func fromUserDefaults() -> SessionPreferencesWindow.Data {
        var data = SessionPreferencesWindow.Data()

        data.comparatorOptions = CommonPrefs.shared.comparatorOptions
        data.displayOptions = CommonPrefs.shared.displayOptions
        data.followSymLinks = CommonPrefs.shared.followSymLinks
        data.skipPackages = CommonPrefs.shared.bool(forKey: .skipPackages)
        data.traverseFilteredFolders = CommonPrefs.shared.bool(forKey: .traverseFilteredFolders)
        data.timestampToleranceSeconds = CommonPrefs.shared.integer(forKey: .timestampToleranceSeconds)
        data.expandAllFolders = CommonPrefs.shared.bool(forKey: .expandAllFolders)
        data.fileExtraOptions = CommonPrefs.shared.fileExtraOptions
        data.fileFilters = SessionDiff.defaultFileFilters()
        data.alignFlags = CommonPrefs.shared.comparatorOptions.onlyAlignFlags
        data.alignRules = [AlignRule]()

        return data
    }

    static func fromSessionDiff(_ sessionDiff: SessionDiff) -> SessionPreferencesWindow.Data {
        var data = SessionPreferencesWindow.Data()

        data.comparatorOptions = sessionDiff.comparatorOptions
        data.displayOptions = sessionDiff.displayOptions
        data.followSymLinks = sessionDiff.followSymLinks
        data.skipPackages = sessionDiff.skipPackages
        data.traverseFilteredFolders = sessionDiff.traverseFilteredFolders
        data.timestampToleranceSeconds = Int(sessionDiff.timestampToleranceSeconds)
        data.expandAllFolders = sessionDiff.expandAllFolders
        data.fileExtraOptions = sessionDiff.fileExtraOptions
        data.fileFilters = sessionDiff.exclusionFileFilters
        data.alignFlags = sessionDiff.comparatorOptions.onlyAlignFlags
        data.alignRules = if let fileNameAlignments = sessionDiff.fileNameAlignments {
            fileNameAlignments
        } else {
            [AlignRule]()
        }

        return data
    }
}
