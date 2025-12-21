//
//  NSApplication.ModalResponse+ReplaceFile.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension NSApplication.ModalResponse {
    enum ReplaceFile: Int {
        case cancel = 1000
        case noToAll = 1001
        // swiftlint:disable:next identifier_name
        case no = 1002
        case yesToAll = 1003
        case yes = 1004

        var title: String {
            switch self {
            case .cancel: NSLocalizedString("Cancel", comment: "")
            case .noToAll: NSLocalizedString("No to All", comment: "")
            case .no: NSLocalizedString("No", comment: "")
            case .yesToAll: NSLocalizedString("Yes to All", comment: "")
            case .yes: NSLocalizedString("Yes", comment: "")
            }
        }

        var keyEquivalent: String {
            switch self {
            case .cancel, .no: KeyEquivalent.escape
            case .noToAll: "o"
            case .yesToAll: "a"
            case .yes: "y"
            }
        }

        var keyDescription: String {
            keyEquivalent == KeyEquivalent.escape ? "Escape" : keyEquivalent
        }

        // periphery:ignore
        var modalResponse: NSApplication.ModalResponse {
            NSApplication.ModalResponse(rawValue: rawValue)
        }
    }

    var replaceFile: ReplaceFile? {
        ReplaceFile(rawValue: rawValue)
    }
}
