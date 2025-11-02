//
//  TimeInterval+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/05/12.
//  Copyright (c) 2012 visualdiffer.com
//

extension TimeInterval {
    func format() -> String {
        if self < 60 {
            return String(format: NSLocalizedString("%.2f seconds", comment: ""), self)
        }
        let longInterval = Int64(self)
        let hours = longInterval / 3600
        let minutes = (longInterval % 3600) / 60
        let seconds = longInterval % 60

        var result = [String]()
        if hours > 0 {
            result.append(String.localizedStringWithFormat(NSLocalizedString("%ld hours", comment: ""), hours))
        }
        if minutes > 0 {
            result.append(String.localizedStringWithFormat(NSLocalizedString("%ld minutes", comment: ""), minutes))
        }
        if seconds > 0 {
            result.append(String.localizedStringWithFormat(NSLocalizedString("%ld seconds", comment: ""), seconds))
        }
        return result.joined(separator: ", ")
    }
}
