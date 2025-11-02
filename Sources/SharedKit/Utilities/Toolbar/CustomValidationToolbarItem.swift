//
//  CustomValidationToolbarItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 03/03/21.
//  Copyright (c) 2021 visualdiffer.com
//

// The delegate validateToolbarItem is called only for Image View Toolbar items
// so we need to subclass it and apply the custom validation
// see "View item validation" at
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Toolbars/Tasks/ValidatingTBItems.html#//apple_ref/doc/uid/20000753-BAJGFHDD
class CustomValidationToolbarItem: NSToolbarItem {
    override func validate() {
        isEnabled = if let target {
            target.validateToolbarItem(self)
        } else {
            false
        }
    }

    override var menuFormRepresentation: NSMenuItem? {
        get {
            let menuItem = NSMenuItem(
                title: label,
                action: action,
                keyEquivalent: ""
            )
            let strongTarget = target
            menuItem.target = strongTarget
            menuItem.isEnabled = if let strongTarget {
                strongTarget.validateToolbarItem(self)
            } else {
                false
            }

            return menuItem
        }

        set {
            super.menuFormRepresentation = newValue
        }
    }
}
