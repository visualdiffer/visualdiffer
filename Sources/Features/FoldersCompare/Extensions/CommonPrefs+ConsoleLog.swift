//
//  CommonPrefs+ConsoleLog.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/07/20.
//  Copyright (c) 2020 visualdiffer.com
//

enum LogLevel: Int {
    case info = 1
    case warning
    case error

    var color: String {
        switch self {
        case .info:
            "info"
        case .warning:
            "warning"
        case .error:
            "error"
        }
    }
}

extension CommonPrefs.Name {
    static let consoleLogFont = CommonPrefs.Name(rawValue: "consoleLogFont")
    static let consoleLogColorsMap = CommonPrefs.Name(rawValue: "consoleLogColorsMap")
}

extension PrefChangedKey.Target {
    static let consoleLog = PrefChangedKey.Target(rawValue: "consoleLog")
}

extension CommonPrefs {
    var consoleLogFont: NSFont {
        get {
            if let font = font(forKey: .consoleLogFont) {
                return font
            }
            let fontManager = NSFontManager.shared
            if let font = fontManager.font(withFamily: "Menlo", traits: .boldFontMask, weight: 0, size: 11.0) {
                return font
            }
            return NSFont.systemFont(ofSize: 11.0)
        }

        set {
            save(newValue, forKey: .consoleLogFont)

            NotificationCenter.default.postPrefsChanged(userInfo: [
                PrefChangedKey.target: PrefChangedKey.Target.consoleLog,
                PrefChangedKey.font: true,
            ])
        }
    }

    func consoleLogColors(_ level: LogLevel) -> ColorSet {
        if let scheme = colorSchemeMap[CommonPrefs.Name.consoleLogColorsMap.rawValue],
           let levelColor = scheme[level.color] {
            return levelColor
        }
        return switch level {
        case .info: ColorSet(text: .textColor, background: .textBackgroundColor)
        case .warning: ColorSet(text: .yellow, background: .textBackgroundColor)
        case .error: ColorSet(text: .red, background: .textBackgroundColor)
        }
    }
}
