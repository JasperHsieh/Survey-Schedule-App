//
//  TimeUtil.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 4/15/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation

extension Date {
    func localString(dateStyle: DateFormatter.Style = .long, timeStyle: DateFormatter.Style = .short) -> String {
        return DateFormatter.localizedString(from: self, dateStyle: dateStyle, timeStyle: timeStyle)
    }
}

/**
Get Date object from time string
- Parameters:
    - time: The time string with "yyyy-MM-dd HH:mm:ssZ" format
- Returns: The Date object
*/
func getTimeFromStr(time: String) -> Date {
    let dateFormatter2 = DateFormatter()
    dateFormatter2.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
    dateFormatter2.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
    return dateFormatter2.date(from:time)!
}

/**
Get the current date
- Returns: The Date object that represents current date
*/
func getCurrentDate() -> Date {
    let currentDate = Date()
    let timezoneOffset =  TimeZone.current.secondsFromGMT()
    let epochDate = currentDate.timeIntervalSince1970
    let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
    return Date(timeIntervalSince1970: timezoneEpochOffset)
}

/**
Get the difference between Date objects
 - Parameters:
    - start: Start date
    - end: End date
 - Returns: The difference in seconds
*/
func getDiffInSec(start: Date, end: Date) -> Int{
    return Int(end.timeIntervalSince(start))
}

/**
Get the current date
 - Parameters:
    - sec: travel time in second
 - Returns: The travel time string on Next Station section
*/
func getTravelTimeString(sec: Int) -> String {
    var hourStr = ""
    var minStr = ""
    let hour = sec / 3600
    let min = (sec % 3600) / 60
    if hour > 0 {
        hourStr = String(hour) + " hr "
    }
    minStr = String(min) + " min"
    return hourStr + minStr
}
