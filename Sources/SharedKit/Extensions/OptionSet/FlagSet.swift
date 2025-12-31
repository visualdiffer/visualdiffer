//
//  FlagSet.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/12/25.
//  Copyright (c) 2025 visualdiffer.com
//

public protocol FlagSet: OptionSet {}

public extension FlagSet {
    @inlinable
    subscript(option: Self.Element) -> Bool {
        get {
            contains(option)
        }
        set {
            if newValue {
                insert(option)
            } else {
                remove(option)
            }
        }
    }
}
