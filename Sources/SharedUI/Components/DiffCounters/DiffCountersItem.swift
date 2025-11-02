//
//  DiffCountersItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/06/15.
//  Copyright (c) 2015 visualdiffer.com
//

class DiffCountersItem: NSObject {
    var text: NSString
    var color: NSColor

    init(withText text: String, color: NSColor) {
        self.text = text as NSString
        self.color = color

        super.init()
    }

    static func diffCounterItem(withText text: String, color: NSColor) -> DiffCountersItem {
        DiffCountersItem(withText: text, color: color)
    }
}
