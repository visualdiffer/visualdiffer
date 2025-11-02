//
//  CompareChangeType.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/06/20.
//  Copyright (c) 2020 visualdiffer.com
//

enum CompareChangeType {
    case unknown
    case orphan
    case old
    case newer
    case changed
    case same
    case folder
    case subFoldersSize
    case filtered
    case mismatchingTags
    case mismatchingLabels
}

extension CompareChangeType: CustomStringConvertible {
    var description: String {
        switch self {
        case .unknown: "unknown"
        case .orphan: "orphan"
        case .old: "old"
        case .newer: "newer"
        case .changed: "changed"
        case .same: "same"
        case .folder: "folder"
        case .subFoldersSize: "subFoldersSize"
        case .filtered: "filtered"
        case .mismatchingTags: "mismatchingTags"
        case .mismatchingLabels: "mismatchingLabels"
        }
    }
}

extension CompareChangeType {
    var color: FolderColorAttribute {
        switch self {
        case .unknown: .unknown
        case .orphan: .orphan
        case .old: .old
        case .newer: .newer
        case .changed: .changed
        case .same: .same
        case .folder: .folder
        case .subFoldersSize: .subFoldersSize
        case .filtered: .filtered
        case .mismatchingTags: .mismatchingTags
        case .mismatchingLabels: .mismatchingLabels
        }
    }
}

extension CommonPrefs {
    func changeTypeColor(_ type: CompareChangeType) -> ColorSet? {
        folderColor(type.color)
    }
}
