//
//  DisplayPositionable.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

public enum DisplaySide: Int, Sendable {
    case left
    case right

    var opposite: DisplaySide {
        self == .left ? .right : .left
    }
}

protocol DisplayPositionable: AnyObject {
    var side: DisplaySide { get set }
}
