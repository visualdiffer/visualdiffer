//
//  NSColor+Hex.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Cocoa

extension NSColor {
    @objc
    static func colorRGBA(_ red: UInt, green: UInt, blue: UInt, alpha: UInt) -> NSColor {
        NSColor(
            calibratedRed: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: CGFloat(alpha) / 255.0
        )
    }

    @objc
    static func colorFromHexRGBA(_ inColorString: String) -> NSColor? {
        var red: UInt = 0
        var green: UInt = 0
        var blue: UInt = 0
        var alpha: UInt = 0

        if hexRGBA(inColorString, red: &red, green: &green, blue: &blue, alpha: &alpha) {
            return colorRGBA(red, green: green, blue: blue, alpha: alpha)
        }
        return nil
    }

    static func hexRGBA(
        _ inColorString: String,
        red: inout UInt,
        green: inout UInt,
        blue: inout UInt,
        alpha: inout UInt
    ) -> Bool {
        let scanner = Scanner(string: inColorString)

        // skip the prefix character if present
        _ = scanner.scanString("#")

        let hexDigitsCount = scanner.string.distance(
            from: scanner.currentIndex,
            to: scanner.string.endIndex
        )
        var hex: UInt64 = 0

        guard scanner.scanHexInt64(&hex) else {
            return false
        }
        switch hexDigitsCount {
        case 3:
            red = UInt((hex >> 8) & 15)
            red += red << 4
            green = UInt((hex >> 4) & 15)
            green += green << 4
            blue = UInt(hex & 15)
            blue += blue << 4
            alpha = 255
        case 6:
            red = UInt((hex >> 16) & 255)
            green = UInt((hex >> 8) & 255)
            blue = UInt(hex & 255)
            alpha = 255
        default:
            red = UInt((hex >> 24) & 255)
            green = UInt((hex >> 16) & 255)
            blue = UInt((hex >> 8) & 255)
            alpha = UInt(hex & 255)
        }
        return true
    }
}
