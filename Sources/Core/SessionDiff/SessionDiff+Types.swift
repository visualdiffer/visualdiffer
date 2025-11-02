//
//  SessionDiff+Types.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension SessionDiff {
    enum ItemType: Int16 {
        case folder = 1
        case file
    }

    enum Column: Int {
        case name = 0
        case size
        case modificationDate
    }

    enum Side: Int {
        case left = 0
        case right
    }
}
