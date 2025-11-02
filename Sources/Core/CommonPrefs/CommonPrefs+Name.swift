//
//  CommonPrefs+Name.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

public extension CommonPrefs {
    struct Name: Hashable, Sendable {
        let rawValue: String

        static let confirmShowInFinderNotVisibleFiles = Name(rawValue: "showInFinderNotVisibleFiles")
        static let confirmReloadFiles = Name(rawValue: "reloadFiles")
        static let confirmStopLongOperation = Name(rawValue: "stopLongOperation")
        static let confirmShowInFinder = Name(rawValue: "showInFinder")
        static let confirmCopy = Name(rawValue: "confirmCopy")
        static let confirmDelete = Name(rawValue: "confirmDelete")
        static let confirmMove = Name(rawValue: "confirmMove")
        static let confirmIncludeFilteredItems = Name(rawValue: "includeFilteredItems")
        static let confirmDontAskToSaveSession = Name(rawValue: "dontAskToSaveSession")

        static let colorsConfigPath = Name(rawValue: "colorsConfigPath")
        static let escCloseWindow = Name(rawValue: "escCloseWindow")

        static let hideEmptyFolders = Name(rawValue: "hideEmptyFolders")
        static let alwaysResolveSymlinks = Name(rawValue: "alwaysResolveSymlinks")
        static let followSymLinks = Name(rawValue: "followSymLinks")
        static let showNotificationWhenWindowIsOnFront = Name(rawValue: "showNotificationWhenWindowIsOnFront")

        static let folderListingFont = Name(rawValue: "folderListingFont")
        static let comparatorFlags = Name(rawValue: "comparatorFlags")
        static let comparatorBinaryBufferSize = Name(rawValue: "comparatorBinaryBufferSize")
        static let displayFilters = Name(rawValue: "displayFilters")
        static let defaultFileFilters = Name(rawValue: "defaultFileFilters")
        static let folderViewDateFormat = Name(rawValue: "folderViewDateFormat")
        static let fileInfoFlags = Name(rawValue: "fileInfoFlags")
        static let traverseFilteredFolders = Name(rawValue: "traverseFilteredFolders")
        static let expandAllFolders = Name(rawValue: "expandAllFolders")

        static let skipPackages = Name(rawValue: "skipPackages")
        static let timestampToleranceSeconds = Name(rawValue: "timestampToleranceSeconds")

        static let folderColorsMap = Name(rawValue: "folderColorsMap")

        static let fileTextFont = Name(rawValue: "fileTextFont")

        static let tabWidth = Name(rawValue: "tabWidth")
        static let defaultEncoding = Name(rawValue: "defaultEncoding")
        static let fileColorsMap = Name(rawValue: "fileColorsMap")
        static let hideFileDiffDetails = Name(rawValue: "hideFileDiffDetails")

        // These are not simple boolean flags
        static let virtualResourceFork = Name(rawValue: "virtualResfork")
        static let virtualFinderLabel = Name(rawValue: "virtualFinderLabel")
        static let virtualFinderTags = Name(rawValue: "virtualFinderTags")
        static let virtualComparatorWithoutMethod = Name(rawValue: "virtualComparatorWithoutMethod")
        static let virtualDisplayFiltersWithoutMethod = Name(rawValue: "virtualDisplayFiltersWithoutMethod")
        static let virtualAlignFlags = Name(rawValue: "VirtualAlignFlags")
        static let virtualAlignRules = Name(rawValue: "VirtualAlignRules")

        init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}
