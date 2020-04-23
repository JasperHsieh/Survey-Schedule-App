//
//  VisitLog.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/25/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation

struct VisitLog: Identifiable, Hashable {
    var id = UUID()
    var station: String
    var timestamp: Int // arrival time
    var isRevisit: Bool
    var index: Int
    var didVisit: Bool

    init(stat: String, timestamp: Int, isRevisit: Bool) {
        self.station = stat
        self.timestamp = timestamp
        self.isRevisit = isRevisit
        self.index = Int.max
        self.didVisit = false
    }

    static func == (lhs: VisitLog, rhs: VisitLog) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func dumpMasterSchedule(schedule: [[[VisitLog]]]) {
        for daySchedule in schedule {
            print("{", terminator: "")
            for visitPath in daySchedule {
                print("[", terminator: "")
                for log in visitPath {
                    dumpLog(visitLog: log)
                }
                print("], ", terminator: "")
            }
            print("}")
        }
    }

    static func dumpDaySchedule(daySchedule: [[VisitLog]]) {
        print("{", terminator: "")
        for visitPath in daySchedule {
            print("[", terminator: "")
            for log in visitPath {
                dumpLog(visitLog: log)
            }
            print("], ", terminator: "")
        }
        print("}")
    }

    static func dumpPath(path visitPath: [VisitLog]) {
        for log in visitPath {
            dumpLog(visitLog: log)
            //print("\(visitLog.station), \(visitLog.timestamp)")
        }
        print()
    }

    static func dumpLog(visitLog: VisitLog) {
        print("(\(visitLog.station),\(visitLog.timestamp),\(visitLog.isRevisit),\(visitLog.index))", terminator: "")
    }

}
