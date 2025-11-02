//
//  CommonPrefs+FileCompare.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

let defaultTabWidth = 4

enum FileColorAttribute: String {
    case added
    case changed
    case deleted
    case lineNumber
    case lineNumberSeparator
    case merged
    case missing
    case positionBox
    case same
    case sectionSeparatorLine
    case selectedRow
    case thumbnail
}

extension CommonPrefs {
    var tabWidth: Int {
        get {
            let value = integer(forKey: .tabWidth)
            return value < 0 ? defaultTabWidth : value
        }

        set {
            set(newValue, forKey: .tabWidth)
            NotificationCenter.default.postPrefsChanged(userInfo: [
                PrefChangedKey.target: PrefChangedKey.Target.file,
                PrefChangedKey.tabWidth: newValue,
            ])
        }
    }

    var defaultEncoding: String.Encoding {
        get {
            if object(forKey: .defaultEncoding) == nil {
                let value = integer(forKey: .defaultEncoding)
                return value < 0 ? .utf8 : String.Encoding(rawValue: UInt(value))
            }
            return .utf8
        }

        set {
            set(newValue.rawValue, forKey: .defaultEncoding)
            NotificationCenter.default.postPrefsChanged(userInfo: [
                PrefChangedKey.target: PrefChangedKey.Target.file,
                PrefChangedKey.encoding: newValue.rawValue,
            ])
        }
    }

    var hideFileDiffDetails: Bool {
        get { bool(forKey: .hideFileDiffDetails) }
        set { set(newValue, forKey: .hideFileDiffDetails) }
    }

    func fileColor(_ name: FileColorAttribute) -> ColorSet? {
        guard let scheme = colorSchemeMap[CommonPrefs.Name.fileColorsMap.rawValue],
              let colorSet = scheme[name.rawValue] else {
            return nil
        }
        return colorSet
    }
}
