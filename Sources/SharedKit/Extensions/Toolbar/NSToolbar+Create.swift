//
//  NSToolbar+Create.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

@objc
extension NSToolbar {
    convenience init(identifier: String, delegate dele: NSToolbarDelegate) {
        self.init(identifier: identifier)

        displayMode = .iconAndLabel
        allowsUserCustomization = true
        autosavesConfiguration = true
        delegate = dele
    }
}
