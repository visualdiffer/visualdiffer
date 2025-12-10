//
//  SessionTypeError.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

enum SessionTypeError: Error {
    case invalidItem(path: String, isFolder: Bool)
    case invalidAllItems(isFolder: Bool)
    case unknownError
}

extension SessionTypeError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .invalidItem(path, isFolder):
            if isFolder {
                String.localizedStringWithFormat(
                    NSLocalizedString("The path '%@' no longer exists or isn't a valid folder", comment: ""), path
                )
            } else {
                String.localizedStringWithFormat(
                    NSLocalizedString("The path '%@' no longer exists or isn't a valid file", comment: ""), path
                )
            }
        case let .invalidAllItems(isFolder):
            isFolder
                // swiftlint:disable:next void_function_in_ternary
                ? NSLocalizedString("The specified paths no longer exist or aren't both folders", comment: "")
                : NSLocalizedString("The specified paths no longer exist or aren't both files", comment: "")
        case .unknownError:
            NSLocalizedString("An unknown error occurred", comment: "")
        }
    }
}
