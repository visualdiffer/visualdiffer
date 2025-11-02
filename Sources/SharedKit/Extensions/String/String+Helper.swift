//
//  String+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/13.
//  Copyright (c) 2013 visualdiffer.com
//

import Foundation

public extension String {
    func hasPrefix(_ prefix: String, ignoreCase: Bool) -> Bool {
        if ignoreCase {
            return range(of: prefix, options: [.caseInsensitive, .anchored]) != nil
        }
        return hasPrefix(prefix)
    }

    func hasSuffix(_ suffix: String, ignoreCase: Bool) -> Bool {
        if ignoreCase {
            return range(of: suffix, options: [.caseInsensitive, .anchored, .backwards]) != nil
        }
        return hasSuffix(suffix)
    }

    func trimmingSuffix(_ prefix: Character) -> String {
        if let index = lastIndex(where: { $0 != prefix }) {
            return String(self[..<self.index(after: index)])
        }
        return self
    }
}
