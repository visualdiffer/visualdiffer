//
//  ColorScheme.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

import os.log

struct ColorSet {
    enum Key: String {
        case text = "textColor"
        case background = "backgroundColor"
    }

    let text: NSColor
    let background: NSColor
}

struct ColorScheme {
    // periphery:ignore
    let name: String
    let colors: [String: ColorSet]

    init(name: String, definitions: [String: [String: String]]) {
        self.name = name
        colors = definitions.mapValues {
            ColorSet(colors: $0)
        }
    }

    subscript(key: String) -> ColorSet? {
        colors[key]
    }
}

extension ColorSet {
    init(colors: [String: String]) {
        var tempText = NSColor.black
        var tempBackground = NSColor.white

        for (key, colorString) in colors {
            let color = Self.resolveColor(from: colorString)

            switch ColorSet.Key(rawValue: key) {
            case .text:
                tempText = color
            case .background:
                tempBackground = color
            default:
                Logger.general.error("Found invalid color type: \(key)")
            }
        }

        text = tempText
        background = tempBackground
    }

    static func resolveColor(from colorString: String) -> NSColor {
        switch colorString {
        case "textForeground":
            NSColor.textColor
        case "textBackground":
            NSColor.textBackgroundColor
        default:
            NSColor.colorFromHexRGBA(colorString) ?? NSColor.black
        }
    }
}
