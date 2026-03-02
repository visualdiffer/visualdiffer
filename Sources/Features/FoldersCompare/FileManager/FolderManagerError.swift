//
//  FolderManagerError.swift
//  VisualDiffer
//
//  Created by davide ficano on 04/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

public enum FolderManagerError: Error {
    case nilPath
    case destinationContainsSelectedSource
}

extension FolderManagerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nilPath:
            "Path is not defined"
        case .destinationContainsSelectedSource:
            "The destination folder cannot match or be inside a selected source path"
        }
    }
}
