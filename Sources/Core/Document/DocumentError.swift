//
//  DocumentError.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

enum DocumentError: Error {
    case invalidSessionData
    case unknownSessionType
}

extension DocumentError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidSessionData:
            NSLocalizedString("Invalid session data; maybe the file is corrupted", comment: "")
        case .unknownSessionType:
            NSLocalizedString("Session type is unknown", comment: "")
        }
    }
}
