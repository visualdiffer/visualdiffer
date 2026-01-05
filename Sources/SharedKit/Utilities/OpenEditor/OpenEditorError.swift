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

extension OpenEditorError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .applicationNotFound(url):
            let message = NSLocalizedString("Application '%@' not found", comment: "")
            return String.localizedStringWithFormat(message, url.osPath)
        case let .missingExecutePermission(url):
            let message = NSLocalizedString("The Unix task '%@' must have the executable flag set (e.g., chmod +x)", comment: "")
            return String.localizedStringWithFormat(message, url.osPath)
        }
    }
}
