//
//  ComparatorOptions.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

public struct ComparatorOptions: OptionSet, Sendable {
    public let rawValue: Int

    public static let timestamp = ComparatorOptions(rawValue: 1 << 0)
    public static let size = ComparatorOptions(rawValue: 1 << 1)
    public static let content = ComparatorOptions(rawValue: 1 << 2)
    public static let contentTimestamp: ComparatorOptions = [.content, .timestamp]
    public static let asText = ComparatorOptions(rawValue: 1 << 3)

    public static let finderLabel = ComparatorOptions(rawValue: 1 << 4)
    public static let finderTags = ComparatorOptions(rawValue: 1 << 5)

    public static let alignFileSystemCase = ComparatorOptions(rawValue: 1 << 6)
    public static let alignMatchCase = ComparatorOptions(rawValue: 1 << 7)
    public static let alignIgnoreCase = ComparatorOptions(rawValue: 1 << 8)

    public static let filename = ComparatorOptions(rawValue: 1 << 9)

    // Masks
    public static let typeMask: ComparatorOptions = [.filename, .timestamp, .size, .content, .asText]
    public static let alignMask: ComparatorOptions = [.alignFileSystemCase, .alignMatchCase, .alignIgnoreCase]
    public static let supportFolderCompare: ComparatorOptions = [.finderLabel, .finderTags]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
