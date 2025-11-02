//
//  DiffChangeType.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/06/15.
//  Copyright (c) 2015 visualdiffer.com
//

enum DiffChangeType {
    case matching
    case added
    case deleted
    case changed
    case missing
}

extension DiffChangeType: CustomStringConvertible {
    var description: String {
        switch self {
        case .added:
            "added"
        case .deleted:
            "deleted"
        case .matching:
            "same"
        case .changed:
            "changed"
        case .missing:
            "missing"
        }
    }
}
