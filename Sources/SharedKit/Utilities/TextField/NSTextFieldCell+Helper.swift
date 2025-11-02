//
//  NSTextFieldCell+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/01/11.
//  Copyright (c) 2011 visualdiffer.com
//

@objc extension NSTextFieldCell {
    var textAttributes: [NSAttributedString.Key: Any] {
        var attributes = [NSAttributedString.Key: Any]()

        var cellTextColor = textColor
        if interiorBackgroundStyle == .emphasized {
            cellTextColor = NSColor.alternateSelectedControlTextColor
        }
        if let cellTextColor {
            attributes[NSAttributedString.Key.foregroundColor] = cellTextColor
        }

        if let font {
            attributes[NSAttributedString.Key.font] = font
        }

        if let paraStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle {
            paraStyle.alignment = alignment
            paraStyle.lineBreakMode = lineBreakMode
            paraStyle.baseWritingDirection = baseWritingDirection

            attributes[NSAttributedString.Key.paragraphStyle] = paraStyle
        }

        return attributes
    }

    func widthNumber(_ number: Int = Int.max) -> CGFloat {
        let str = if let formatter {
            formatter.string(for: number) ?? String(format: "%lld", number)
        } else {
            String(format: "%lld", number)
        }
        return (str as NSString).size(withAttributes: textAttributes).width
    }

    func widthString(_ str: String) -> CGFloat {
        (str as NSString).size(withAttributes: textAttributes).width
    }
}
