//
//  URL+Finder.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension URL {
    func labelNumber() -> Int? {
        guard let resources = try? resourceValues(forKeys: [.labelNumberKey]) else {
            return nil
        }
        return resources.labelNumber
    }

    func tagNames(sorted: Bool) -> [String]? {
        guard let resources = try? resourceValues(forKeys: [.tagNamesKey]) else {
            return nil
        }
        guard let tagNames = resources.tagNames else {
            return []
        }

        return if sorted {
            tagNames.sorted { $0.caseInsensitiveCompare($1) == .orderedAscending }
        } else {
            tagNames
        }
    }
}
