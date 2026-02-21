//
//  NSTextView+Style.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/11/11.
//  Copyright (c) 2011 visualdiffer.com
//

@objc
extension NSTextView {
    func setTabStop(_ tabSpaces: Int) {
        guard let font else {
            return
        }
        guard let paragraphStyle = defaultParagraphStyle?.mutableCopy() as? NSMutableParagraphStyle
            ?? NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle else {
            return
        }
        let charWidth = (" " as NSString).size(withAttributes: [.font: font]).width

        paragraphStyle.defaultTabInterval = charWidth * Double(tabSpaces)
        paragraphStyle.tabStops = []
        defaultParagraphStyle = paragraphStyle

        var typingAttributes = typingAttributes
        typingAttributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        typingAttributes[NSAttributedString.Key.font] = font
        self.typingAttributes = typingAttributes

        let rangeOfChange = NSRange(location: 0, length: string.count)
        shouldChangeText(in: rangeOfChange, replacementString: nil)
        textStorage?.setAttributes(
            typingAttributes,
            range: rangeOfChange
        )

        didChangeText()
    }

    func disableWordWrap() {
        guard let textContainer else {
            return
        }
        let largeNumberForText = 1.0e7

        textContainer.containerSize = NSSize(width: largeNumberForText, height: largeNumberForText)
        textContainer.widthTracksTextView = false
        maxSize = NSSize(width: largeNumberForText, height: maxSize.height)
        isHorizontallyResizable = true
    }

    func setTextColor(_ textColor: NSColor?, backgroundColor: NSColor?) {
        if textColor == nil, backgroundColor == nil {
            return
        }
        guard let textStorage else {
            return
        }
        let string = textStorage.string
        let length = string.count

        // remove the old colors
        let area = NSRange(location: 0, length: length)
        textStorage.removeAttribute(NSAttributedString.Key.foregroundColor, range: area)
        textStorage.removeAttribute(NSAttributedString.Key.backgroundColor, range: area)

        if let textColor {
            textStorage.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: textColor,
                range: area
            )
        }
        if let backgroundColor {
            textStorage.addAttribute(
                NSAttributedString.Key.backgroundColor,
                value: backgroundColor,
                range: area
            )
        }
    }

    func append(text: String, attributes: [NSAttributedString.Key: Any]? = nil) {
        let attrString = NSAttributedString(string: text, attributes: attributes)
        if let textStorage {
            textStorage.append(attrString)
        }
        scrollRangeToVisible(NSRange(location: string.count, length: 0))
    }
}
