//
//  DateBuilder.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/02/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

public struct DateBuilder {
    let isoDateFormatter: DateFormatter

    public init() {
        isoDateFormatter = DateFormatter()
        isoDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss z"
        isoDateFormatter.locale = Locale.current
        isoDateFormatter.timeZone = TimeZone.current
        isoDateFormatter.formatterBehavior = .default
    }

    public func isoDate(_ strDate: String) throws -> Date {
        guard let date = isoDateFormatter.date(from: strDate) else {
            throw NSError(domain: "Unable to parse date", code: 0, userInfo: nil)
        }
        return date
    }
}
