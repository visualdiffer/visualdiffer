//
//  FileManager+Attributes.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/01/14.
//  Copyright (c) 2014 visualdiffer.com
//

import Foundation

public extension FileManager {
    /**
     * 'Modification date' change isn't reliable on smb volumes
     * sometimes it's ignored without reporting error so this method
     * uses an hack to bypass this bug.
     * The hack consists to call twice the setAttribute for modification date on smb
     */
    func setFileAttributes(
        _ attrs: [FileAttributeKey: Any],
        ofItemAtPath path: URL,
        volumeType type: String
    ) throws {
        try setFileAttributes(
            attrs,
            ofItemAtPath: path.osPath,
            volumeType: type
        )
    }

    @objc func setFileAttributes(
        _ attrs: [FileAttributeKey: Any],
        ofItemAtPath path: String,
        volumeType type: String
    ) throws {
        if type == "smbfs" {
            let creation = attrs[.creationDate] as? Date
            let modification = attrs[.modificationDate] as? Date

            if creation != nil || modification != nil {
                var patchedAttrs = attrs
                var correctDates = [FileAttributeKey: Any]()

                if let creation {
                    patchedAttrs[.creationDate] = Date()
                    correctDates[.creationDate] = creation
                }
                if let modification {
                    patchedAttrs[.modificationDate] = Date()
                    correctDates[.modificationDate] = modification
                }
                try setAttributes(
                    patchedAttrs,
                    ofItemAtPath: path
                )
                try setAttributes(
                    correctDates,
                    ofItemAtPath: path
                )
            }
        }
        // and set attributes the second time...
        try setAttributes(
            attrs,
            ofItemAtPath: path
        )
    }
}

extension [FileAttributeKey: Any] {
    var fileAttributeType: FileAttributeType? {
        if let type = self[.type] as? String {
            FileAttributeType(rawValue: type)
        } else {
            nil
        }
    }
}
