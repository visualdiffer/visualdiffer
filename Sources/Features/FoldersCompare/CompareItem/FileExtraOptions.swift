//
//  FileExtraOptions.swift
//  VisualDiffer
//
//  Created by davide ficano on 03/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

public struct FileExtraOptions: OptionSet, Sendable {
    public let rawValue: Int

    static let resourceFork = FileExtraOptions(rawValue: 1 << 0)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public extension FileExtraOptions {
    var hasCheckResourceForks: Bool {
        contains(.resourceFork)
    }

    func changeCheckResourceForks(_ isOn: Bool) -> Self {
        if isOn {
            union(.resourceFork)
        } else {
            subtracting(.resourceFork)
        }
    }
}
