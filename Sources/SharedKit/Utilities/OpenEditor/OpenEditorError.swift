//
//  OpenEditorError.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

enum OpenEditorError: Error {
    case applicationNotFound(URL)
    case missingExecutePermission(URL)
}

// swiftlint:disable line_length
extension OpenEditorError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .applicationNotFound(url):
            let message = NSLocalizedString("Application not found '%@'", comment: "")
            return String.localizedStringWithFormat(message, url.osPath)
        case let .missingExecutePermission(url):
            let message = NSLocalizedString("The unix task '%@' must have the execute flag set (eg chmod +x)", comment: "")
            return String.localizedStringWithFormat(message, url.osPath)
        }
    }
}

// swiftlint:enable line_length
