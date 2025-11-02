//
//  DiffLine+Color.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/06/15.
//  Copyright (c) 2015 visualdiffer.com
//

extension DiffLine {
    var colors: ColorSet? {
        let color: FileColorAttribute = mode == .merged ? .merged : type.color
        return CommonPrefs.shared.fileColor(color)
    }

    func color(for colorKey: ColorSet.Key, isSelected: Bool) -> NSColor {
        var color: NSColor?

        if isSelected {
            if colorKey == .text {
                color = colors?.text
            } else if colorKey == .background {
                color = CommonPrefs.shared.fileColor(.selectedRow)?.background
            }
        } else {
            if colorKey == .text {
                color = colors?.text
            } else if colorKey == .background {
                color = colors?.background
            }
        }

        return color ?? NSColor.black
    }
}
