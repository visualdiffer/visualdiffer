//
//  LinkButton.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

class LinkButton: NSButton {
    init(title: String, target: AnyObject? = nil, action: Selector? = nil) {
        super.init(frame: .zero)

        self.title = title
        self.target = target
        self.action = action

        styleAsLink()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    func styleAsLink() {
        isBordered = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]

        attributedTitle = NSAttributedString(string: title, attributes: attributes)
    }
}
