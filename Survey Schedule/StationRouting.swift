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
    let N: Int = 2 * 60 * 60
    let M: Int = 15 * 60
    let measureTime = 150

    func getVisitPath(statList: [String], pathSoFar: [VisitLog]) -> [VisitLog]{
        let minTimePerm = getMinTimePermutation(statList: statList)
        let simulateResult = simulateVisitStations(statList: minTimePerm, pathSoFar: pathSoFar)
        return simulateResult
    }

    func simulateVisitStations(statList: [String], pathSoFar: [VisitLog]) -> [VisitLog] {

        var curTime = 0
        var lastRepeatTime = 0
        var visitPath: [VisitLog] = []
        var statSeq = statList

        // Update current time
        if !pathSoFar.isEmpty {
            curTime = pathSoFar.last!.timestamp + getStatsTravelTime(stat1: pathSoFar.last!.station, stat2: statSeq.first!)
            // update repeat time?
        }

        var curStat = statSeq.first ?? ""

        while !statSeq.isEmpty {
            if let index = statSeq.firstIndex(of: curStat) {
                statSeq.remove(at: index)
            }

            visitPath.append(VisitLog(stat: curStat, timestamp: curTime))
            curTime += measureTime * 3

            if curTime - lastRepeatTime > N {
                // Handle revisit
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
                        let curTravelTime = getStatsTravelTime(stat1: curStat, stat2: visitLog.station)
                        if curTravelTime < M && (curTime + curTravelTime - visitLog.timestamp > N) && curTravelTime < minTravelTime {
                            minTravelTime = curTravelTime
                            minVisitLog = visitLog
                        }
                    }

                    // Update current station and time
                    if let visitLog = minVisitLog {
                        curStat = visitLog.station
                        curTime += minTravelTime
                        lastRepeatTime = curTime
                    }else{
                        print("No valid station to revisit")
                    }

                    // Update visit order
                    let tmpStatList = [curStat] + statSeq
                    statSeq = getMinTimePermutationWithStart(startStat: curStat, statList: tmpStatList)
                    continue
                }
            }

            // Update current station
            if !statSeq.isEmpty {
                let nextStat = statSeq[0]
                let travelToNextTime = getStatsTravelTime(stat1: curStat, stat2: nextStat)
                curTime += travelToNextTime
                curStat = nextStat
            }
        }

        return visitPath
    }

    func getMinTimePermutationWithStart(startStat: String, statList: [String]) -> [String] {
        let allPerms = statList.permutations()
        var minTime = Int.max
        var minPerm: [String] = []

        for perm in allPerms {
            if perm[0] == startStat {
                continue
            }
            let time = getTotalVisitTime(statList: statList)
            if time < minTime {
                minTime = time
                minPerm = perm
            }
        }
        return minPerm
    }

    func getMinTimePermutation(statList: [String]) -> [String]{
        let allPerms = statList.permutations()
        var minTime = Int.max
        var minPerm: [String] = []

        for perm in allPerms {
            let time = getTotalVisitTime(statList: statList)
            if time < minTime {
                minTime = time
                minPerm = perm
            }
        }
        return minPerm
    }

    func getTotalVisitTime(statList: [String]) -> Int {
        var totalTime = 0
        var preStat = statList[0]

        for stat in statList {
            if stat != statList[0] {
                totalTime += getStatsTravelTime(stat1: preStat, stat2: stat)
            }
            totalTime += measureTime
            preStat = stat
        }
        return totalTime
    }

    func getStatsTravelTime(stat1: String, stat2: String) -> Int {
        print("getStatsTravelTime \(stat1) and \(stat2)")
        if DataUtil.statTravelTime?[stat1].string == nil || DataUtil.statTravelTime?[stat2].string == nil {
            print("\(stat1) or \(stat2) not found in travel time file")
            return Int.max
        }
        if let time = DataUtil.statTravelTime?[stat1][stat2].int {
            return time
        } else{
            print("Coundn't find \(stat2) from \(stat1) item")
            return Int.max
        }
    }
}
