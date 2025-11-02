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
}

protocol DisplayPositionable: AnyObject {
    var side: DisplaySide { get set }
}
