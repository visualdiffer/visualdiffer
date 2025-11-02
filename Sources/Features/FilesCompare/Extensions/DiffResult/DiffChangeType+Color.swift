//
//  DiffChangeType+Color.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/06/15.
//  Copyright (c) 2015 visualdiffer.com
//

extension DiffChangeType {
    var colors: ColorSet? {
        CommonPrefs.shared.fileColor(color)
    }

    var color: FileColorAttribute {
        switch self {
        case .matching:
            .same
        case .added:
            .added
        case .deleted:
            .deleted
        case .changed:
            .changed
        case .missing:
            .missing
        }
    }
}
