//
//  FileError.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

public enum FileError: Error, Equatable {
    case symlinkLoop(path: String)
    case createSymLink(path: String)
    case openFile(path: String)
    case fileNotExists(path: URL, side: DisplaySide)
    case unknownVolumeType
}

// swiftlint:disable line_length
extension FileError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .symlinkLoop(path):
            let message = NSLocalizedString("Detected recursive loop for symbolic link '%@'", comment: "")
            return String.localizedStringWithFormat(message, path)
        case let .openFile(path):
            let message = NSLocalizedString("Unable to open file '%@'", comment: "")
            return String.localizedStringWithFormat(message, path)
        case let .createSymLink(path):
            let message = NSLocalizedString("Unable to create symbolic link to destination '%@' because the existing file isn't a symbolic link", comment: "")
            return String.localizedStringWithFormat(message, path)
        case let .fileNotExists(path, side):
            let message = switch side {
            case .left:
                NSLocalizedString("Left file '%@' no longer exists", comment: "")
            case .right:
                NSLocalizedString("Right file '%@' no longer exists", comment: "")
            }
            return String.localizedStringWithFormat(message, path.osPath)
        case .unknownVolumeType:
            return NSLocalizedString("Unable to determine the disk volume type", comment: "")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .fileNotExists:
            NSLocalizedString("Maybe it was located in a temporary directory and another process deleted it", comment: "")
        default:
            nil
        }
    }
}

// swiftlint:enable line_length
