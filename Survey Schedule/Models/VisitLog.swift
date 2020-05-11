//
//  VisitLog.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/25/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation

/**
Represent a scheduled station that shoud be visited on the master schedule.
*/
class VisitLog: Identifiable, Hashable {

    /// Unique id of the visit log
    var id = UUID()

    /// The station name that should be visited
    var station: String

    /// A time interval that represents the arrval time at station. The start of time interval is the first first when calling getCompleteSchedule of **ClusterRouting** class.
    var timestamp: Int

    /// Indicate the visit log is for revisiting or not
    var isRevisit: Bool

    /// The index of master schedule
    var index: Int

    /// Indicate whether the visit log has been visited or not
    var didVisit: Bool

    /// The timestamp that shows on master schedule
    var date: Date

    /// Indicate the visit log is skipped or not
    var isSkip: Bool

    /**
    Initialize a new station
       - Parameters:
           - stat: The station name
           - timestamp: The time interval that starts from the currentStat of getCompleteSchedule of class **ClusterRouting**
           - isRevisit: The whether the visit log is for revisit or not
    */
    init(stat: String, timestamp: Int, isRevisit: Bool) {
        self.station = stat
        self.timestamp = timestamp
        self.isRevisit = isRevisit
        self.index = Int.max
        self.didVisit = false
        self.date = getTimeFromStr(time: "2020-01-01 09:00:00+00000")
        self.isSkip = false
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
        //print("(\(visitLog.station),\(visitLog.date),\(visitLog.timestamp),\(visitLog.index))", terminator: "")
        print("(\(visitLog.station),\(visitLog.didVisit),\(visitLog.isRevisit),\(visitLog.isSkip),\(visitLog.date))", terminator: "")
    }

}
