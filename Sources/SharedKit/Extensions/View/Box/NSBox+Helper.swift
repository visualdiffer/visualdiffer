//
//  NSBox+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

@objc extension NSBox {
    static func separator() -> NSBox {
        let view = NSBox()

        view.boxType = .separator
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }
}
