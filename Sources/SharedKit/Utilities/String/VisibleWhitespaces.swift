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

    func getString(_ component: DiffLineComponent, isWhitespacesVisible: Bool) -> DisplayLine {
        if isWhitespacesVisible {
            return showWhitespaces(component.text + component.eol.visibleSymbol)
        }
        return Self.tabs2space(component.text, tabWidth: tabWidth)
    }

    static func tabs2space(_ line: String, tabWidth: Int) -> DisplayLine {
        guard tabWidth > 0, line.contains("\t") else {
            return DisplayLine(text: line, offsets: [])
        }

        var dest = ""
        var destCount = 0
        var offsets = [Int]()

        offsets.reserveCapacity(line.count + 1)

        for ch in line {
            offsets.append(destCount)

            if ch == "\t" {
                let spaces = tabWidth - (destCount % tabWidth)
                dest += String(repeating: " ", count: spaces)
                destCount += spaces
            } else {
                dest.append(ch)
                destCount += 1
            }
        }
        offsets.append(destCount)

        return DisplayLine(text: dest, offsets: offsets)
    }

    func showWhitespaces(_ line: String) -> DisplayLine {
        guard tabWidth > 0 else {
            return DisplayLine(text: line, offsets: [])
        }

        let whitespaces = CharacterSet.whitespaces
        // every character but a tab is replaced one by one, so the mapping is needed
        // only when the line contains a tab
        let needsOffsets = line.contains("\t")
        var dest = ""
        var destCount = 0
        var offsets = [Int]()

        if needsOffsets {
            offsets.reserveCapacity(line.count + 1)
        }

        for ch in line {
            if needsOffsets {
                offsets.append(destCount)
            }

            guard let scalar = ch.unicodeScalars.first,
                  whitespaces.contains(scalar) else {
                dest.append(ch)
                destCount += 1
                continue
            }

            if ch == "\t" {
                // subtract from spaces the character representing TAB
                let spaces = (tabWidth - (destCount % tabWidth)) - 1
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
                    destCount += spaces + 1
                } else {
                    dest += Self.visibleTab
                    destCount += 1
                }
            } else {
                dest += getVisibleCharFor(ch)
                destCount += 1
            }
        }

        if needsOffsets {
            offsets.append(destCount)
        }

        return DisplayLine(text: dest, offsets: offsets)
    }
}
