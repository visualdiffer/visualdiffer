//
//  NotificationCenter+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

enum FileUpdatedKey: String, Hashable {
    case leftPath
    case rightPath
}

enum PrefChangedKey: String, Hashable {
    struct Target: RawRepresentable {
        var rawValue: String

        static let folder = Target(rawValue: "folder")
        static let file = Target(rawValue: "file")
    }

    case target
    case font
    case encoding
    case tabWidth
}

extension Notification.Name {
    static let prefsChanged = NSNotification.Name("com.visualdiffer.notification.prefsChanges")
    static let appAppearanceDidChange = NSNotification.Name("com.visualdiffer.notification.appAppearanceDidChange")
    static let fileUpdated = NSNotification.Name("com.visualdiffer.notification.fileUpdated")
}

extension NotificationCenter {
    func postPrefsChanged(userInfo: [AnyHashable: Any]? = nil) {
        post(
            name: .prefsChanged,
            object: nil,
            userInfo: userInfo
        )
    }

    func postFileUpdated(leftPath: String?, rightPath: String?) {
        var userInfo = [FileUpdatedKey: String]()

        if let path = leftPath {
            userInfo[.leftPath] = path
        }
        if let path = rightPath {
            userInfo[.rightPath] = path
        }
        NotificationCenter.default.post(
            name: .fileUpdated,
            object: nil,
            userInfo: userInfo
        )
    }
}
