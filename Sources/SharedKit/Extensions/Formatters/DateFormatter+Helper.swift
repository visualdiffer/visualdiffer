//
//  DateFormatter+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/01/11.
//  Copyright (c) 2011 visualdiffer.com
//

@objc
extension DateFormatter {
    func widthOfLongestDateStringWithLevel(attrs: [NSAttributedString.Key: Any]) -> CGFloat {
        // This code is rather tied to the gregorian date.
        // We pick an arbitrary date, and iterate through each of the days of the week
        // and each of the months to find the longest string for the given detail level.
        // Because a person can customize (via the intl prefs) the string,
        // we need to iterate through each level for each item.
        let weekDayCount = weekdaySymbols.isEmpty ? 7 : weekdaySymbols.count

        var dateComponents = DateComponents()
        dateComponents.year = 2015
        dateComponents.month = 5
        dateComponents.day = 16
        dateComponents.hour = 10
        dateComponents.minute = 40
        dateComponents.second = 30
        dateComponents.timeZone = TimeZone.current
        let gregorian = Calendar(identifier: .gregorian)

        // Find the longest week day
        var longestWeekDay = 1
        var result: CGFloat = 0

        for dayOfWeek in 1 ... weekDayCount {
            dateComponents.day = dayOfWeek
            if let date = gregorian.date(from: dateComponents) {
                let str = string(from: date)
                let length = (str as NSString).size(withAttributes: attrs).width
                if length > result {
                    result = length
                    longestWeekDay = dayOfWeek
                }
            }
        }

        let monthCount = monthSymbols.isEmpty ? 12 : monthSymbols.count

        for month in 1 ... monthCount {
            dateComponents.day = longestWeekDay
            dateComponents.month = month
            if let date = gregorian.date(from: dateComponents) {
                let str = string(from: date)
                let length = (str as NSString).size(withAttributes: attrs).width
                result = max(result, length)
            }
        }

        return result
    }
}
