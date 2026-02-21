//
//  KeyEquivalent.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

// swiftlint:disable identifier_name
@objc
class KeyEquivalent: NSObject {
    @objc static let leftArrow = "\u{2190}"
    @objc static let rightArrow = "\u{2192}"
    @objc static let upArrow = "\u{2191}"
    @objc static let downArrow = "\u{2193}"

    @objc static let deleteBackspace = "\u{0008}"
    @objc static let forwardDelete = "\u{007F}"

    @objc static let enter = "\r"
    @objc static let escape = "\u{001B}"
    @objc static let tab = "\t"

    @objc static let f1 = "\u{F704}"
    @objc static let f2 = "\u{F705}"
    @objc static let f3 = "\u{F706}"
    @objc static let f4 = "\u{F707}"
    @objc static let f5 = "\u{F708}"
    @objc static let f6 = "\u{F709}"
    @objc static let f7 = "\u{F70A}"
    @objc static let f8 = "\u{F70B}"
    @objc static let f9 = "\u{F70C}"
    @objc static let f10 = "\u{F70D}"
    @objc static let f11 = "\u{F70E}"
    @objc static let f12 = "\u{F70F}"
}

// swiftlint:enable identifier_name
