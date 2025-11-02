//
//  NSToolbarItem+Create.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

@objc extension NSToolbarItem {
    convenience init(
        identifier: NSToolbarItem.Identifier,
        label: String,
        tooltip: String?,
        image: NSImage?,
        target: AnyObject?,
        action: Selector?
    ) {
        self.init(itemIdentifier: identifier)
        _ = with(
            label: label,
            tooltip: tooltip,
            image: image,
            target: target,
            action: action
        )
    }

    func with(
        label: String,
        tooltip: String?,
        image: NSImage?,
        target: AnyObject?,
        action: Selector?
    ) -> Self {
        self.label = label
        paletteLabel = label

        toolTip = tooltip
        self.image = image

        self.target = target
        self.action = action

        return self
    }
}
