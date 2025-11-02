//
//  StringUtils.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

public func generateAsciiChar() -> Character {
    // swiftlint:disable:next force_unwrapping
    Character(Unicode.Scalar(Int.random(in: 0 ..< 26) + 97)!)
}

public func invertCase(_ str: inout String, index: Int) {
    let len = str.count
    guard len > 0 else {
        return
    }
    let index = str.index(str.startIndex, offsetBy: index)
    let ch: Character = str[index]
    let inverted = ch.isUppercase ? str[index].lowercased() : str[index].uppercased()
    str.replaceSubrange(index ... index, with: inverted)
}
