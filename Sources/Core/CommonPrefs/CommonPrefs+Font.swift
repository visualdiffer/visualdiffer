//
//  CommonPrefs+Font.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension CommonPrefs {
    func restoreDefaultFonts() {
        removeObject(forKey: .folderListingFont)
        removeObject(forKey: .fileTextFont)

        folderListingFont = defaultFolderListingFont()
        fileTextFont = defaultFileTextFont()
    }

    func defaultFolderListingFont() -> NSFont {
        NSFontManager.shared.font(
            withFamily: "Lucida Grande",
            traits: [],
            weight: 0,
            size: 11.0
        )
            ?? NSFont.systemFont(ofSize: 11.0)
    }

    func defaultFileTextFont() -> NSFont {
        NSFontManager.shared.font(
            withFamily: "monaco",
            traits: [],
            weight: 0,
            size: 11.0
        )
            ?? NSFont.monospacedSystemFont(ofSize: 11.0, weight: .regular)
    }

    var folderListingFont: NSFont {
        get {
            guard let font = font(forKey: .folderListingFont) else {
                return defaultFolderListingFont()
            }
            return font
        }

        set {
            save(newValue, forKey: .folderListingFont)
            NotificationCenter.default.postPrefsChanged(userInfo: [
                PrefChangedKey.target: PrefChangedKey.Target.folder,
                PrefChangedKey.font: true,
            ])
        }
    }

    var fileTextFont: NSFont {
        get {
            guard let font = font(forKey: .fileTextFont) else {
                return defaultFolderListingFont()
            }
            return font
        }

        set {
            save(newValue, forKey: .fileTextFont)
            NotificationCenter.default.postPrefsChanged(userInfo: [
                PrefChangedKey.target: PrefChangedKey.Target.file,
                PrefChangedKey.font: true,
            ])
        }
    }

    func font(forKey key: CommonPrefs.Name) -> NSFont? {
        if let descriptorData = UserDefaults.standard.data(forKey: key.rawValue),
           let fontDescriptor = try? NSKeyedUnarchiver.unarchivedObject(
               ofClass: NSFontDescriptor.self,
               from: descriptorData
           ),
           let font = NSFont(descriptor: fontDescriptor, size: 0) {
            return font
        }
        return nil
    }

    func save(_ font: NSFont, forKey key: CommonPrefs.Name) {
        let descriptorData = try? NSKeyedArchiver.archivedData(
            withRootObject: font.fontDescriptor,
            requiringSecureCoding: false
        )
        UserDefaults.standard.setValue(descriptorData, forKeyPath: key.rawValue)
    }
}
