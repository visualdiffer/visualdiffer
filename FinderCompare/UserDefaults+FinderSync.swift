//
//  UserDefaults+FinderSync.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/01/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Foundation

private let leftPathKey = "compareLeftPath"
private let rightPathKey = "compareRightPath"

extension UserDefaults {
    func compareItem() throws -> FinderCompareItem? {
        if let path = string(forKey: leftPathKey) {
            return try FinderCompareItem(url: URL(filePath: path), side: .left)
        }
        if let path = string(forKey: rightPathKey) {
            return try FinderCompareItem(url: URL(filePath: path), side: .right)
        }
        return nil
    }

    func setCompareItem(url: URL, side: DisplaySide) {
        let key = side == .left ? leftPathKey : rightPathKey
        set(url.path(percentEncoded: false), forKey: key)
    }

    func removeCompareItem() {
        removeObject(forKey: leftPathKey)
        removeObject(forKey: rightPathKey)
    }
}
