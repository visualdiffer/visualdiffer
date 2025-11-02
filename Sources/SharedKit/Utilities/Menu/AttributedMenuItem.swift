//
//  AttributedMenuItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

struct AttributedMenuItem {
    var text: String
    var attributes: [NSAttributedString.Key: Any]

    static func createAttributes(
        title: String,
        description: String,
        descriptionColor: NSColor,
        font: NSFont
    ) -> [AttributedMenuItem] {
        [
            AttributedMenuItem(text: title, attributes: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: NSColor.controlTextColor,
            ]),
            AttributedMenuItem(text: description, attributes: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: descriptionColor,
            ]),
        ]
    }

    static func createTitle(_ items: [AttributedMenuItem]) -> NSAttributedString {
        var str = ""

        for data in items {
            str += data.text
        }
        let attrString = NSMutableAttributedString(string: str)

        attrString.beginEditing()
        var normalRange = NSRange()

        for data in items {
            let text = data.text
            let attrs = data.attributes
            normalRange.length = text.count
            attrString.addAttributes(attrs, range: normalRange)
            normalRange.location += text.count
        }
        attrString.endEditing()

        return attrString
    }
}
