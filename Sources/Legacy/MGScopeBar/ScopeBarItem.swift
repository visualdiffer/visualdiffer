//
//  ScopeBarItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

enum ScopeBarGroupKey: String {
    case label = "Label" // string
    case separator = "HasSeparator" // Bool as NSNumber
    case selectionMode = "SelectionMode" // MGScopeBarGroupSelectionMode (int) as NSNumber
    case items = "Items" // array of dictionaries, each containing the following keys
}

enum ScopeBarItem: String {
    case identifier = "Identifier" // string
    case name = "Name" // string
}
