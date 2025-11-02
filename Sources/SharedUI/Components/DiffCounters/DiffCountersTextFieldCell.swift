//
//  DiffCountersTextFieldCell.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/06/15.
//  Copyright (c) 2015 visualdiffer.com
//

let kDotWidth: CGFloat = 10.0
let kDotPaddingEnd: CGFloat = 4.0
let kTextPaddingEnd: CGFloat = 4.0
let kStrokelineWidth: CGFloat = 1.0
let kDotBlendFraction: CGFloat = 0.5

class DiffCountersTextFieldCell: NSTextFieldCell {
    @objc var counterItems = [DiffCountersItem]()

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        if !stringValue.isEmpty {
            super.draw(withFrame: cellFrame, in: controlView)
            return
        }
        var attrs: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: NSColor.controlTextColor,
        ]

        if let font {
            attrs[NSAttributedString.Key.font] = font
        }

        var rect = cellFrame
        rect.origin.x += kStrokelineWidth
        rect.size = NSSize(width: kDotWidth, height: kDotWidth)

        for item in counterItems {
            let textSize = item.text.size(withAttributes: attrs)

            var dotRect = rect
            var textOrigin = NSPoint(x: rect.origin.x + dotRect.size.width + kDotPaddingEnd, y: rect.origin.y)
            let offset = (textSize.height - dotRect.size.height) / 2

            // the dot height is smaller than the text so center it
            if offset > 0 {
                dotRect.origin.y += offset
            } else {
                // the dot height is taller than the text so center the text
                textOrigin.y -= offset
            }
            drawDot(item.color, rect: dotRect, strokeLineWidth: kStrokelineWidth)

            item.text.draw(at: textOrigin, withAttributes: attrs)
            // move to next dot position
            rect.origin.x = textOrigin.x + textSize.width + kTextPaddingEnd
        }
    }

    func drawDot(
        _ color: NSColor,
        rect: NSRect,
        strokeLineWidth: CGFloat
    ) {
        let strokeColor = NSColor.highlightColor
        let path = NSBezierPath()
        path.appendOval(in: rect)
        path.lineWidth = strokeLineWidth
        color.setFill()
        strokeColor.setStroke()
        path.stroke()
        path.fill()
    }
}
