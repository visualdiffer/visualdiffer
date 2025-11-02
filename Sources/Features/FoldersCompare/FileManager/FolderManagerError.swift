//
//  FolderManagerError.swift
//  VisualDiffer
//
//  Created by davide ficano on 04/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

public enum FolderManagerError: Error {
    case nilPath
}

extension FolderManagerError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nilPath:
            "Path is not defined"
        }
    }
}
