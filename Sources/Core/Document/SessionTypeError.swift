//
//  SessionTypeError.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

enum SessionTypeError: Error {
    case invalidItem(
        isDir: Bool,
        leftExists: Bool,
        rightExists: Bool
    )
    case invalidAllItems(isDir: Bool)
}

extension SessionTypeError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .invalidItem(isDir, leftExists, rightExists):
            Self.invalidPathMessage(isDir: isDir, leftExists: leftExists, rightExists: rightExists)
        case let .invalidAllItems(isDir):
            Self.invalidPathMessage(isDir: isDir, leftExists: false, rightExists: false)
        }
    }

    static func invalidPathMessage(
        isDir: Bool,
        leftExists: Bool,
        rightExists: Bool
    ) -> String {
        switch (isDir, leftExists, rightExists) {
        case (true, false, false):
            NSLocalizedString("The specified paths no longer exist or aren't both folders", comment: "")
        case (false, false, false):
            NSLocalizedString("The specified paths no longer exist or aren't both files", comment: "")
        case (true, true, true):
            NSLocalizedString("Left path is a folder but the right is a file; both must be folders or files", comment: "")
        case (false, true, true):
            NSLocalizedString("Left path is a file but the right is a folder; both must be folders or files", comment: "")
        case (true, false, _):
            NSLocalizedString("Left path no longer exists or isn't a valid folder", comment: "")
        case (false, false, _):
            NSLocalizedString("Left path no longer exists or isn't a valid file", comment: "")
        case (true, _, false):
            NSLocalizedString("Right path no longer exists or isn't a valid folder", comment: "")
        case (false, _, false):
            NSLocalizedString("Right path no longer exists or isn't a valid file", comment: "")
        }
    }
}
