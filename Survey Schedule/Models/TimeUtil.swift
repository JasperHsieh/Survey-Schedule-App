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

func getTimeFromStr(time: String) -> Date {
    let dateFormatter2 = DateFormatter()
    dateFormatter2.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
    dateFormatter2.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
    return dateFormatter2.date(from:time)!
}

func getCurrentDate() -> Date {
    var currentDate = Date()
    let timezoneOffset =  TimeZone.current.secondsFromGMT()
    let epochDate = currentDate.timeIntervalSince1970
    let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
    return Date(timeIntervalSince1970: timezoneEpochOffset)
}

func getDiffInSec(start: Date, end: Date) -> Int{
    return Int(end.timeIntervalSince(start))
}

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
