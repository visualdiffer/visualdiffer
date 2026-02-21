//
//  NSAppearance+DarkMode.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/10/20.
//  Copyright (c) 2020 visualdiffer.com
//

extension NSAppearance {
    static var isDarkMode: Bool {
        if #available(macOS 10.14, *) {
            return MainActor.assumeIsolated {
                let basicAppearance = NSApp.effectiveAppearance.bestMatch(from: [
                    NSAppearance.Name.aqua,
                    NSAppearance.Name.darkAqua,
                ])
                return basicAppearance == NSAppearance.Name.darkAqua
            }
        }
        // check 'AppleInterfaceStyle'
        return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }

    @objc
    @MainActor
    static func change() {
        if #available(macOS 10.14, *) {
            switch UserDefaults.standard.integer(forKey: "appAppearance") {
            case 1:
                NSApp.appearance = NSAppearance(named: .aqua)
            case 2:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            default:
                break
            }
        }
    }
}
