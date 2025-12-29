//
//  CommonPrefs+FolderCompare.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

let defaultComparatorBinaryBufferSize = 2 * 1024 * 1024

enum FolderColorAttribute: String {
    case unknown
    case orphan
    case old
    case newer
    case changed
    case same
    case folder
    case subFoldersSize
    case filtered
    case mismatchingLabels
    case mismatchingTags
    case selectedRow
}

extension CommonPrefs {
    // MARK: - Comparator

    var comparatorOptions: ComparatorOptions {
        get {
            var flags = if let number = object(forKey: .comparatorFlags) as? NSNumber {
                ComparatorOptions(number: number)
            } else {
                ComparatorOptions.timestamp
            }
            if flags.onlyAlignFlags.isEmpty {
                flags.insert(.alignMatchCase)
            }
            return flags
        }

        set {
            set(newValue.rawValue, forKey: .comparatorFlags)
            NotificationCenter.default.post(name: .prefsChanged, object: "comparatorFlags")
        }
    }

    var comparatorWithoutMethod: ComparatorOptions {
        get {
            comparatorOptions.onlyMethodFlags
        }

        set {
            comparatorOptions = comparatorOptions.changeWithoutMethod(newValue)
        }
    }

    var finderLabel: Bool {
        get {
            comparatorOptions.hasFinderLabel
        }

        set {
            comparatorOptions = comparatorOptions.changeFinderLabel(newValue)
        }
    }

    var finderTags: Bool {
        get {
            comparatorOptions.hasFinderTags
        }

        set {
            comparatorOptions = comparatorOptions.changeFinderTags(newValue)
        }
    }

    // MARK: - DisplayOptions

    var displayOptions: DisplayOptions {
        get {
            if let value = object(forKey: .displayFilters) as? NSNumber {
                DisplayOptions(number: value)
            } else {
                .showAll
            }
        }

        set {
            set(newValue.rawValue, forKey: .displayFilters)
            NotificationCenter.default.post(name: .prefsChanged, object: "displayFilters")
        }
    }

    var displayFiltersWithoutMethod: DisplayOptions {
        get {
            displayOptions.onlyMethodFlags
        }

        set {
            displayOptions = displayOptions.changeWithoutMethod(newValue)
        }
    }

    // MARK: - FileExtraOptions

    var fileExtraOptions: FileExtraOptions {
        get {
            FileExtraOptions(rawValue: integer(forKey: .fileInfoFlags))
        }

        set {
            set(newValue.rawValue, forKey: .fileInfoFlags)
        }
    }

    var checkResourceForks: Bool {
        get {
            fileExtraOptions.hasCheckResourceForks
        }

        set {
            fileExtraOptions = fileExtraOptions.changeCheckResourceForks(newValue)
        }
    }

    // MARK: - Filters

    var defaultFileFilters: String? {
        get {
            object(forKey: .defaultFileFilters) as? String
        }

        set {
            if let newValue {
                set(newValue, forKey: .defaultFileFilters)
            } else {
                removeObject(forKey: .defaultFileFilters)
            }
        }
    }

    var alwaysResolveSymlinks: Bool {
        get { bool(forKey: .alwaysResolveSymlinks) }
        set { set(newValue, forKey: .alwaysResolveSymlinks) }
    }

    var followSymLinks: Bool {
        get { bool(forKey: .followSymLinks) }
        set { set(newValue, forKey: .followSymLinks) }
    }

    var comparatorBinaryBufferSize: Int {
        get {
            let value = number(forKey: .comparatorBinaryBufferSize, defaultComparatorBinaryBufferSize).intValue
            return value < 0 ? defaultComparatorBinaryBufferSize : value
        }

        set {
            set(newValue, forKey: .comparatorBinaryBufferSize)
        }
    }

    var showNotificationWhenWindowIsOnFront: Bool {
        get { bool(forKey: .showNotificationWhenWindowIsOnFront) }
        set { set(newValue, forKey: .showNotificationWhenWindowIsOnFront) }
    }

    var folderViewDateFormat: String {
        get { string(forKey: .folderViewDateFormat) ?? "ddMMyyHHmmss" }
        set { set(newValue, forKey: .folderViewDateFormat) }
    }

    var hideEmptyFolders: Bool {
        get { bool(forKey: .hideEmptyFolders) }
        set { set(newValue, forKey: .hideEmptyFolders) }
    }

    func folderColor(_ name: FolderColorAttribute) -> ColorSet? {
        guard let scheme = colorSchemeMap[CommonPrefs.Name.folderColorsMap.rawValue],
              let colorSet = scheme[name.rawValue] else {
            return nil
        }
        return colorSet
    }
}
