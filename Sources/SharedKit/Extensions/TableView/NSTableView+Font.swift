//
//  NSTableView+Font.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

@objc
extension NSTableView {
    func updateFont(
        _ font: NSFont,
        reloadData reload: Bool
    ) {
        let layoutManager = NSLayoutManager()
        rowHeight = layoutManager.defaultLineHeight(for: font) + 4

        if reload {
            reloadData()
        }
    }
}
