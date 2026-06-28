//
//  ComparatorOptions+Description.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension ComparatorOptions: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .filename:
            NSLocalizedString("Name", comment: "")
        case .asText:
            NSLocalizedString("Content (Ignore Line Endings)", comment: "")
        case .content:
            NSLocalizedString("Content", comment: "")
        case .size:
            NSLocalizedString("Size", comment: "")
        case .timestamp:
            NSLocalizedString("Timestamp", comment: "")
        case [.timestamp, .size]:
            NSLocalizedString("Timestamp + Size", comment: "")
        case [.timestamp, .content, .size]:
            NSLocalizedString("Timestamp + Size + Content", comment: "")
        default:
            "\(rawValue)"
        }
    }

    public var debugDescription: String {
        var arr = [String]()

        if contains(.timestamp) {
            arr.append("TIMESTAMP")
        }
        if contains(.size) {
            arr.append("SIZE")
        }
        if contains(.content) {
            arr.append("CONTENT")
        }
        if contains(.asText) {
            arr.append("AS_TEXT")
        }
        if contains(.filename) {
            arr.append("FILENAME")
        }

        if contains(.finderLabel) {
            arr.append("FINDER_LABEL")
        }
        if contains(.finderTags) {
            arr.append("FINDER_TAGS")
        }

        if contains(.alignFileSystemCase) {
            arr.append("ALIGN_FILESYSTEM_CASE")
        }
        if contains(.alignMatchCase) {
            arr.append("ALIGN_MATCH_CASE")
        }
        if contains(.alignIgnoreCase) {
            arr.append("ALIGN_IGNORE_CASE")
        }

        return arr.joined(separator: ",")
    }
}
