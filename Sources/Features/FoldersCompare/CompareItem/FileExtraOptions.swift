//
//  FileExtraOptions.swift
//  VisualDiffer
//
//  Created by davide ficano on 03/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

public struct FileExtraOptions: FlagSet, Sendable {
    public let rawValue: Int

    static let resourceFork = FileExtraOptions(rawValue: 1 << 0)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
