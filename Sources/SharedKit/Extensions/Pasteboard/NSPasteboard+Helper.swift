//
//  NSPasteboard+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension NSPasteboard {
    @discardableResult
    @objc
    func copy(lines: [String]) -> Bool {
        clearContents()
        return writeObjects([lines.joined(separator: "\n")] as [NSString])
    }

    @discardableResult
    @objc
    func copy(urls: [URL]) -> Bool {
        if urls.isEmpty {
            return false
        }
        clearContents()
        return writeObjects(urls as [NSURL])
    }
}
