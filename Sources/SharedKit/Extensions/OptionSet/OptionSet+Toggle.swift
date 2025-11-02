//
//  OptionSet+Toggle.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension OptionSet {
    func toggled(_ member: Self) -> Self {
        symmetricDifference(member)
    }

    // periphery:ignore
    mutating func toggle(_ member: Self) {
        formSymmetricDifference(member)
    }
}
