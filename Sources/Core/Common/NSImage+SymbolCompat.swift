//
//  NSImage+SymbolCompat.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/03/21.
//  Copyright (c) 2021 visualdiffer.com
//

import Foundation

@objc extension NSImage {
    static func imageSymbolCompat(_ name: NSImage.Name) -> NSImage? {
        if #available(macOS 11.0, *) {
            if let symbolInfo = symbolMap[name] {
                return NSImage(systemSymbolName: symbolInfo[0], accessibilityDescription: symbolInfo[1])
            }
        }
        return NSImage(named: name)
    }

    private static let symbolMap: [NSImage.Name: [String]] = [
        NSImage.preferencesGeneralName: ["gearshape", "Preferences"],
        NSImage.fontPanelName: ["textformat.size", "Fonts"],
        NSImage.Name("prefs_text"): ["doc.plaintext", "Text Preferences"],
        NSImage.Name("prefs_paths"): ["lock.open", "Trusted Paths"],
        NSImage.Name("prefs_folder"): ["folder", "Folder"],
        NSImage.Name("prefs_confirmations"): ["exclamationmark.triangle", "Confirmations"],
        NSImage.Name("prefs_keyboard"): ["command", "Keyboard"],
    ]
}
