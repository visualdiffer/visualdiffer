//
//  NSTextField+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

@objc extension NSTextField {
    static func labelWithTitle(_ title: String) -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.stringValue = title
        view.isEditable = false
        view.isSelectable = false
        view.drawsBackground = false
        view.isBordered = false
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    static func hintWithTitle(_ title: String) -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.stringValue = title
        view.isEditable = false
        view.isSelectable = false
        view.drawsBackground = false
        view.isBordered = false
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }
}
