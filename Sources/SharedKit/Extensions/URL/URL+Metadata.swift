//
//  URL+Metadata.swift
//  VisualDiffer
//
//  Created by davide ficano on 03/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

public extension URL {
    func copyTags(to toUrl: inout URL) throws {
        let resources = try resourceValues(forKeys: [.tagNamesKey])
        try toUrl.setResourceValues(resources)
    }

    func copyLabel(to toUrl: inout URL) throws {
        let resources = try resourceValues(forKeys: [.labelNumberKey])
        try toUrl.setResourceValues(resources)
    }
}
