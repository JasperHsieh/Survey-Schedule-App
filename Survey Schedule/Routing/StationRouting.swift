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
    let Debug = false
    let N: Int = 2 * 60 * 60
    //let N: Int = 30 * 60
    let M: Int = 15 * 60
    let measureTime = 150
    //let dataUtil = DataUtil()
    //let clusterInfo = DataUtil.clusterInfo

    var lastRepeatTime = 0

    func getVisitPath(statList: [String], pathSoFar: [VisitLog]) -> [VisitLog]{
        let minTimePerm = getMinTimePermutation(statList: statList)
        let simulateResult = simulateVisitStations(statList: minTimePerm, pathSoFar: pathSoFar)
        //VisitLog.dumpPath(path: simulateResult)
        return simulateResult
    }

    func getVisitPath(statList: [String], pathSoFar: [VisitLog], cluster: String) -> [VisitLog]{
        var minTimePerm: [String] = getMinPermStationFromCache(stations: statList)
        if minTimePerm.isEmpty {
            minTimePerm = getMinTimePermutation(statList: statList)
            setMinPermToCache(minPerm: minTimePerm)
        }
        let simulateResult = simulateVisitStations(statList: minTimePerm, pathSoFar: pathSoFar)
        //VisitLog.dumpPath(path: simulateResult)
        return simulateResult
    }

    func simulateVisitStations(statList: [String], pathSoFar: [VisitLog]) -> [VisitLog] {

        var curTime = 0
        var visitPath: [VisitLog] = []
        var statSeq = statList

        if(Debug) {print("simulateVisitStations: \(statList), lastRepeat:\(lastRepeatTime), N:\(N)")}
        // Update current path and time
        if !pathSoFar.isEmpty {
            if(Debug) {print("pathSoFar:")}
            if(Debug) {VisitLog.dumpPath(path: pathSoFar)}
            curTime = pathSoFar.last!.timestamp + getStatsTravelTime(stat1: pathSoFar.last!.station, stat2: statSeq.first!)
            //lastRepeatTime = curTime
            if(Debug) {print("Update currentTime to \(curTime)")}
            // update repeat time?
        }

        var curVisitLog = VisitLog(stat: statSeq.first ?? "", timestamp: curTime, isRevisit: false)

        while !statSeq.isEmpty {
            //print()
            //print("*** \(curStat) \(curTime) \(statSeq) ***")
            //VisitLog.dumpPath(path: visitPath)
            if let index = statSeq.firstIndex(of: curVisitLog.station) {
                statSeq.remove(at: index)
            }

            visitPath.append(curVisitLog)
            curTime += measureTime * 3

            if curTime - lastRepeatTime > N {
                // Handle revisit
                if(Debug) {print("Time to revisit \(curTime), last repeat: \(lastRepeatTime)")}
                if visitPath.isEmpty {
                    print("Couldn't find revisit station")
                } else{
                    // Find closest revisit station
                    var minTravelTime = Int.max
                    var minVisitLog: VisitLog?
                    for visitLog in (visitPath + pathSoFar) {
                        if curVisitLog.station == visitLog.station {
                            continue
                        }
                        let curTravelTime = getStatsTravelTime(stat1: curVisitLog.station, stat2: visitLog.station)
                        if curTravelTime < M && (curTime + curTravelTime - visitLog.timestamp > N) && curTravelTime < minTravelTime {
                            minTravelTime = curTravelTime
                            minVisitLog = visitLog
                        }
                    }
                    if let visitLog = minVisitLog {
                        // Revisit station and update current station and time
                        curTime += minTravelTime
                        lastRepeatTime = curTime
                        curVisitLog = VisitLog(stat: visitLog.station, timestamp: curTime, isRevisit: true)
                        if(Debug) {print("Revisit \(visitLog.station) \(curTime)")}
                        // Update visit order
                        let tmpStatList = [curVisitLog.station] + statSeq
                        statSeq = getMinTimePermutationWithStart(startStat: curVisitLog.station, statList: tmpStatList)
                        //print("New visit sequence \(statSeq)")
                        continue
                    }else{
                        if(Debug) {print("No valid station to revisit")}
                    }
                }
            }

            // Update current station
            if !statSeq.isEmpty {
                let nextStat = statSeq[0]
                let travelToNextTime = getStatsTravelTime(stat1: curVisitLog.station, stat2: nextStat)
                curTime += travelToNextTime
                curVisitLog = VisitLog(stat: nextStat, timestamp: curTime, isRevisit: false)
            }
            //VisitLog.dumpPath(path: visitPath)
            //print("\(curTime)")
        }
        if(Debug) {print("Done simulation")}
        if(Debug) {VisitLog.dumpPath(path: visitPath)}
        return visitPath
    }

    func getStartStat(statList: [String]) -> String {
        if statList.isEmpty {
            print("statList is empty")
            return ""
        }
        let start = getStartStationFromCache(stations: statList)
        if start != InvalidStation {
            //print("get start \(start) from cache")
            return start
        } else {
            let minPerm = getMinTimePermutation(statList: statList)
            setMinPermToCache(minPerm: minPerm)
            return minPerm.first!
        }
    }

    func getMinTimePermutationWithStart(startStat: String, statList: [String]) -> [String] {
        //print("getMinTimePermutationWithStart start... \(startStat) \(statList)")
        var minPerm = getMinPermWithStartStationFromCache(stations: statList)
        if !minPerm.isEmpty {
            //print("Found in cache \(minPerm)")
            return minPerm
        }
        
        let allPerms = statList.permutations()
        var minTime = Int.max

        for perm in allPerms {
            if perm[0] != startStat {
                continue
            }
            let curTime = getTotalVisitTime(statList: perm)
            //print("\(perm) \(curTime)")
            if curTime < minTime {
                minTime = curTime
                minPerm = perm
            }
        }
        //print("getMinTimePermutationWithStart complete... \(minTime)")
        return minPerm
    }

    func getMinTimePermutation(statList: [String]) -> [String]{
        //print("getMinTimePermutation start...")
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
        //print("getMinTimePermutation complete...")
        //print("minPerm: \(minTime) \(minPerm)")
        return minPerm
    }

    func getTotalVisitTime(statList: [String]) -> Int {
        var totalTime = 0
        var preStat = ""

        for (i, stat) in statList.enumerated() {
            //print("i=\(i) \(preStat) \(stat)")
            if i > 0 {
                totalTime += getStatsTravelTime(stat1: preStat, stat2: stat)
            }
            totalTime += measureTime
            preStat = stat
        }
        //print("getTotalVisitTime: \(totalTime)")
        return totalTime
    }

    func resetRepeatTime(){
        self.lastRepeatTime = 0
    }
}
