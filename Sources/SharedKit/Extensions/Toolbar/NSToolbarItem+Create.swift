//
//  NSToolbarItem+Create.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

@objc
extension NSToolbarItem {
    convenience init(
        identifier: NSToolbarItem.Identifier,
        label: String,
        tooltip: String?,
        image: NSImage?,
        target: AnyObject?,
        action: Selector?,
        isBordered: Bool = true
    ) {
        self.init(itemIdentifier: identifier)
        _ = with(
            label: label,
            tooltip: tooltip,
            image: image,
            target: target,
            action: action,
            isBordered: isBordered
        )
    }

    func with(
        label: String,
        tooltip: String?,
        image: NSImage?,
        target: AnyObject?,
        action: Selector?,
        isBordered: Bool = true
    ) -> Self {
        self.label = label
        paletteLabel = label

        self.isBordered = isBordered

        toolTip = tooltip
        self.image = image

        self.target = target
        self.action = action

        return self
    }
}

extension NSToolbarItem {
    static func createOpenWithPopup(
        identifier: NSToolbarItem.Identifier,
        menuIdentifier: NSUserInterfaceItemIdentifier,
        target: AnyObject,
        action: Selector,
        menuDelegate: NSMenuDelegate
    ) -> NSToolbarItem {
        let popupButton = NSPopUpButton(
            identifier: menuIdentifier,
            menuTitle: NSLocalizedString("ToolbarOpenWith", comment: ""),
            menuImage: VDSymbol.Toolbar.openWith.image()
        )
        popupButton.target = target
        popupButton.action = action
        popupButton.menu?.delegate = menuDelegate

        let item = CustomValidationToolbarItem(
            identifier: identifier,
            label: NSLocalizedString("Open With", comment: ""),
            tooltip: NSLocalizedString("Open using the selected application", comment: ""),
            image: VDSymbol.Toolbar.showInFinder.image(),
            target: nil,
            action: nil
        )
        item.view = popupButton

        return item
    }
}
