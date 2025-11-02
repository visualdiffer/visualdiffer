//
//  NSPopUpButton+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

@objc extension NSPopUpButton {
    convenience init(
        identifier: NSUserInterfaceItemIdentifier,
        menuTitle: String,
        menuImage: NSImage?
    ) {
        self.init(frame: .zero, pullsDown: true)

        bezelStyle = .texturedRounded
        setButtonType(.momentaryPushIn)
        imagePosition = .imageOnly
        alignment = .left
        lineBreakMode = .byTruncatingTail
        state = .on
        isBordered = true
        imageScaling = .scaleProportionallyDown

        let menuItem = NSMenuItem()
        menuItem.state = .on
        menuItem.image = menuImage
        menuItem.isHidden = true

        let popupMenu = NSMenu(title: menuTitle)
        popupMenu.identifier = identifier
        popupMenu.addItem(menuItem)

        menu = popupMenu
    }
}
