//
//  EncodingError.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

enum EncodingError: Error {
    case conversionFailed(String.Encoding)
}

extension EncodingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .conversionFailed(encoding):
            // do not use localizedStringWithFormat to avoid formatting the number
            String(format: NSLocalizedString("Can't convert to encoding: %ld", comment: ""), encoding.rawValue)
        }
    }
}
