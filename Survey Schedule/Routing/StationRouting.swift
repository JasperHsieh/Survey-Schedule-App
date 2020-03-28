//
//  StationRouting.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/24/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import Combinatorics

class StationRouting {
    let N: Int = 30 * 60
    let M: Int = 15 * 60
    let measureTime = 150
    let dataUtil = DataUtil()

    func getVisitPath(statList: [String], pathSoFar: [VisitLog]) -> [VisitLog]{
        let minTimePerm = getMinTimePermutation(statList: statList)
        let simulateResult = simulateVisitStations(statList: minTimePerm, pathSoFar: pathSoFar)
        dumpPath(visitPath: simulateResult)
        return simulateResult
    }

    func simulateVisitStations(statList: [String], pathSoFar: [VisitLog]) -> [VisitLog] {

        var curTime = 0
        var lastRepeatTime = 0
        var visitPath: [VisitLog] = []
        var statSeq = statList

        // Update current time
        if !pathSoFar.isEmpty {
            curTime = pathSoFar.last!.timestamp + dataUtil.getStatsTravelTime(stat1: pathSoFar.last!.station, stat2: statSeq.first!)
            // update repeat time?
        }

        print("simulateVisitStations: \(statList)")
        var curStat = statSeq.first ?? ""

        while !statSeq.isEmpty {
            print()
            print("*** \(curStat) \(curTime) \(statSeq) ***")
            dumpPath(visitPath: visitPath)
            if let index = statSeq.firstIndex(of: curStat) {
                statSeq.remove(at: index)
            }

            visitPath.append(VisitLog(stat: curStat, timestamp: curTime))
            curTime += measureTime * 3

            if curTime - lastRepeatTime > N {
                // Handle revisit
                print("Time to revisit \(curTime), last repeat: \(lastRepeatTime)")
                if visitPath.isEmpty {
                    print("Couldn't find revisit station")
                } else{
                    // Find closest revisit station
                    var minTravelTime = Int.max
                    var minVisitLog: VisitLog?
                    for visitLog in visitPath {
                        if curStat == visitLog.station {
                            continue
                        }
                        let curTravelTime = dataUtil.getStatsTravelTime(stat1: curStat, stat2: visitLog.station)
                        if curTravelTime < M && (curTime + curTravelTime - visitLog.timestamp > N) && curTravelTime < minTravelTime {
                            minTravelTime = curTravelTime
                            minVisitLog = visitLog
                        }
                    }
                    if let visitLog = minVisitLog {
                        // Revisit station and update current station and time
                        print("Revisit \(visitLog.station)")
                        curStat = visitLog.station
                        curTime += minTravelTime
                        lastRepeatTime = curTime

                        // Update visit order
                        let tmpStatList = [curStat] + statSeq
                        statSeq = getMinTimePermutationWithStart(startStat: curStat, statList: tmpStatList)
                        print("New visit sequence \(statSeq)")
                        continue
                    }else{
                        print("No valid station to revisit")
                    }
                }
            }

            // Update current station
            if !statSeq.isEmpty {
                let nextStat = statSeq[0]
                let travelToNextTime = dataUtil.getStatsTravelTime(stat1: curStat, stat2: nextStat)
                curTime += travelToNextTime
                curStat = nextStat
            }
            //dumpPath(visitPath: visitPath)
            //print("\(curTime)")
        }
        print("Done simulation")
        dumpPath(visitPath: visitPath)
        return visitPath
    }

    func getStartStat(statList: [String]) -> String {
        if statList.isEmpty {
            print("statList is empty")
            return ""
        }
        let minPerm = getMinTimePermutation(statList: statList)
        return minPerm.first!
    }

    func getMinTimePermutationWithStart(startStat: String, statList: [String]) -> [String] {
        print("getMinTimePermutationWithStart start...")
        let allPerms = statList.permutations()
        var minTime = Int.max
        var minPerm: [String] = []

        for perm in allPerms {
            if perm[0] != startStat {
                continue
            }
            let time = getTotalVisitTime(statList: statList)
            if time < minTime {
                minTime = time
                minPerm = perm
            }
        }
        print("getMinTimePermutationWithStart complete...")
        return minPerm
    }

    func getMinTimePermutation(statList: [String]) -> [String]{
        let allPerms = statList.permutations()
        var minTime = Int.max
        var minPerm: [String] = []
        //print("getMinTimePermutation: \(allPerms)")
        for perm in allPerms {
            let time = getTotalVisitTime(statList: perm)
            if time < minTime {
                minTime = time
                minPerm = perm
            }
        }
        print("minPerm: \(minTime) \(minPerm)")
        return minPerm
    }

    func getTotalVisitTime(statList: [String]) -> Int {
        var totalTime = 0
        var preStat = statList[0]

        for stat in statList {
            if stat != statList[0] {
                totalTime += dataUtil.getStatsTravelTime(stat1: preStat, stat2: stat)
            }
            totalTime += measureTime
            preStat = stat
        }
        //print("getTotalVisitTime: \(totalTime)")
        return totalTime
    }

    func dumpPath(visitPath: [VisitLog]) {
        for log in visitPath {
            dumpLog(visitLog: log)
            //print("\(visitLog.station), \(visitLog.timestamp)")
        }
        print()
    }

    func dumpLog(visitLog: VisitLog) {
        print("(\(visitLog.station), \(visitLog.timestamp))", terminator: "")
    }

//    func getStatsTravelTime(stat1: String, stat2: String) -> Int {
//        print("getStatsTravelTime \(stat1) and \(stat2)")
//        if DataUtil.statTravelTimeInfo?[stat1].string == nil || DataUtil.statTravelTimeInfo?[stat2].string == nil {
//            print("\(stat1) or \(stat2) not found in travel time file")
//            //return Int.max
//        }
//
//        if let time = DataUtil.statTravelTimeInfo?[stat1][stat2].int {
//            print("\(stat1) and \(stat2) time: \(time)")
//            return time
//        } else{
//            print("Coundn't find \(stat2) from \(stat1) item")
//            return Int.max
//        }
//    }
}
