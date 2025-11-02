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
            NSLocalizedString("Compare file names only", comment: "")
        case .asText:
            NSLocalizedString("Compare file content ignoring line ending differences", comment: "")
        case .content:
            NSLocalizedString("Compare file content only", comment: "")
        case .size:
            NSLocalizedString("Compare file sizes", comment: "")
        case .timestamp:
            NSLocalizedString("Compare file timestamps", comment: "")
        case [.timestamp, .size]:
            NSLocalizedString("Compare file timestamps and sizes", comment: "")
        case [.timestamp, .content, .size]:
            NSLocalizedString("Compare file timestamp, size and content", comment: "")
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
