//
//  NSButton+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Cocoa
import Foundation

extension NSButton {
    static func button(title: String, keyEquivalent: String) -> NSButton {
        let view = NSButton(frame: .zero)
        view.title = title
        view.setButtonType(.momentaryPushIn)

        view.isBordered = true
        view.state = .off
        view.bezelStyle = .flexiblePush
        view.imagePosition = .noImage
        view.alignment = .center
        view.keyEquivalent = keyEquivalent
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    static func cancelButton(title: String, target: Any? = nil, action: Selector? = nil) -> NSButton {
        let button = NSButton(
            title: title,
            target: target,
            action: action
        )
        button.keyEquivalent = KeyEquivalent.escape
        button.tag = NSApplication.ModalResponse.cancel.rawValue
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }

    static func okButton(title: String, target: Any? = nil, action: Selector? = nil) -> NSButton {
        let button = NSButton(
            title: title,
            target: target,
            action: action
        )
        button.keyEquivalent = KeyEquivalent.enter
        button.tag = NSApplication.ModalResponse.OK.rawValue
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }
}
