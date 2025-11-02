//
//  TextFieldVerticalCentered.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

class TextFieldVerticalCentered: NSTextFieldCell {
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        let titleSize = attributedStringValue.size()
        var titleFrame = super.titleRect(forBounds: rect)
        titleFrame.origin.y = rect.origin.y + (rect.size.height - titleSize.height) / 2.0

        return titleFrame
    }

    override func drawInterior(withFrame cellFrame: NSRect, in _: NSView) {
        let titleRect = titleRect(forBounds: cellFrame)
        attributedStringValue.draw(in: titleRect)
    }
}
