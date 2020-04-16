//
//  VisitLog.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/25/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation

class VisitLog: Identifiable {
    var id = UUID()
    var station: String
    var timestamp: Int // arrival time
    var isRevisit: Bool
    init(stat: String, timestamp: Int, isRevisit: Bool) {
        self.station = stat
        self.timestamp = timestamp
        self.isRevisit = isRevisit
    }

    static func dumpPath(path visitPath: [VisitLog]) {
        for log in visitPath {
            dumpLog(visitLog: log)
            //print("\(visitLog.station), \(visitLog.timestamp)")
        }
        print()
    }

    static func dumpLog(visitLog: VisitLog) {
        print("(\(visitLog.station),\(visitLog.timestamp),\(visitLog.isRevisit)) ", terminator: "")
    }

}
