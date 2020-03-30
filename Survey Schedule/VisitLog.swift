//
//  VisitLog.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/25/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation

class VisitLog {
    var station: String
    var timestamp: Int
    init(stat: String, timestamp: Int) {
        self.station = stat
        self.timestamp = timestamp
    }

    static func dumpPath(path visitPath: [VisitLog]) {
        for log in visitPath {
            dumpLog(visitLog: log)
            //print("\(visitLog.station), \(visitLog.timestamp)")
        }
        print()
    }

    static func dumpLog(visitLog: VisitLog) {
        print("(\(visitLog.station), \(visitLog.timestamp))", terminator: "")
    }

}
