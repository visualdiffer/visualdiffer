//
//  VisibleWhitespaces.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/01/11.
//  Copyright (c) 2011 visualdiffer.com
//

class VisibleWhitespaces: NSObject {
    static let visibleTab = "\u{BB}"
    static let visibleSpace = "\u{B7}"

    @objc var tabWidth = 4

    func getVisibleCharFor(_ ch: Character) -> String {
        if ch == " " {
            return Self.visibleSpace
        }
        return String(ch)
    }

    @objc func getString(_ str: String, isWhitespacesVisible: Bool) -> String {
        if isWhitespacesVisible {
            return showWhitespaces(str)
        }
        return Self.tabs2space(str, tabWidth: tabWidth)
    }

    static func tabs2space(_ line: String, tabWidth: Int) -> String {
        var dest = ""

        for ch in line {
            if ch == "\t" {
                let spaces = tabWidth - (dest.count % tabWidth)
                dest += String(repeating: " ", count: spaces)
            } else {
                dest.append(ch)
            }
        }
        return dest
    }

    func showWhitespaces(_ line: String) -> String {
        let whitespaces = CharacterSet.whitespaces
        var dest = ""

        for ch in line {
            guard let scalar = ch.unicodeScalars.first,
                  whitespaces.contains(scalar) else {
                dest.append(ch)
                continue
            }
            if ch == "\t" {
                // subtract from spaces the character representing TAB
                let spaces = (tabWidth - (dest.count % tabWidth)) - 1
                if spaces > 0 {
                    let leftSpaces = spaces / 2
                    let rightSpaces = spaces - leftSpaces

                    if leftSpaces > 0 {
                        dest += String(repeating: " ", count: leftSpaces)
                    }
                    dest += Self.visibleTab
                    if rightSpaces > 0 {
                        dest += String(repeating: " ", count: rightSpaces)
                    }
                } else {
                    dest += Self.visibleTab
                }
            } else {
                dest += getVisibleCharFor(ch)
            }
        }
        return dest
    }
}
