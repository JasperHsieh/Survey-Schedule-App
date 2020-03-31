//
//  ClusterRouting.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/23/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import SwiftyJSON

class ClusterRouting{
    var clusterStartId = 100

    var clusterInfo: JSON
    var workingTime: Int
    let dataUtil: DataUtil
    let stationRouting: StationRouting

    init(clusterInfo: JSON, workingTime: Int){
        self.clusterInfo = clusterInfo
        self.workingTime = workingTime
        self.dataUtil = DataUtil()
        self.stationRouting = StationRouting()
    }

    func getNextDaySchedule(info clusterInfo: JSON, workingTime: Int) -> Dictionary<Int, Any>{
        //let statInfo = DataUtil.statInfo
        var clusterInfo = DataUtil.clusterInfo!
        clusterInfo = resetVisitedStatus(jsonObj: clusterInfo)

        let startStat = "CS25"
        let startTime = 0
        var preStat = startStat
        var visitPath: [VisitLog] = [VisitLog(stat: preStat, timestamp: startTime, isRevisit: false)]
        var day = 1

        print("getNextDaySchedule \(workingTime)")
        //while !visitedAll(jsonObj: clusterInfo){
        while true {
            // choose the closest cluster
            var nextCluster = "-1"
            var minTime = Int.max
            //print(clusterInfo)
            for (cluster, _) in clusterInfo {
                if !clusterInfo[cluster]["visited"].bool! {
                    //print("Checking cluster \(cluster)")
                    let travelTime = dataUtil.getStatsTravelTime(stat1: preStat, stat2: clusterInfo[cluster]["start"].string!)
                    if travelTime < minTime {
                        minTime = travelTime
                        nextCluster = cluster
                        //print("nextCluster \(nextCluster) \(minTime)")
                    }
                }
            }
            if nextCluster == "-1" {
                print("Something wrong wiht finding next cluster")
                break
            }

            // Check if we finish next cluster in time
            print()
            print("*** Checking cluster \(nextCluster) ***")
            //var nextClusterVisitPath = stationRouting.getVisitPath(statList: clusterInfo[nextCluster]["stations"].arrayObject as! [String], pathSoFar: visitPath)
            var nextClusterVisitPath = stationRouting.getVisitPath(statList: clusterInfo[nextCluster]["stations"].arrayObject as! [String], pathSoFar: visitPath, cluster: nextCluster)
            let nextClusterLastVisitLog = nextClusterVisitPath.last!
            let nextClusterFinishTime = nextClusterLastVisitLog.timestamp + dataUtil.getStatsTravelTime(stat1: nextClusterLastVisitLog.station, stat2: startStat)

            if nextClusterFinishTime > workingTime {
                // Exceed workingTime today, cut cluster
                print("Exceed workingTime limit, check cutting cluster")
                for i in (0..<nextClusterVisitPath.count).reversed() {
                    let log = nextClusterVisitPath[i]
                    if log.isRevisit {
                        print("Ignore repeat station")
                        continue
                    }
                    let timeToFinish = log.timestamp + dataUtil.getStatsTravelTime(stat1: log.station, stat2: startStat)
                    //print("Checking \()")
                    print("Checking last station \(log.station) \(timeToFinish)")
                    if timeToFinish < workingTime {
                        // Form new cluster from left stations
                        print("Cut cluster")
                        let newCluster = String(clusterStartId)
                        clusterStartId += 1
                        clusterInfo[newCluster] = JSON()
                        clusterInfo[newCluster]["visited"] = false
                        var remainStats: [String] = []
                        for visitLog in Array(nextClusterVisitPath[(i+1)...]) {
                            remainStats.append(visitLog.station)
                        }
                        print("RemainStats: \(remainStats)")
                        clusterInfo[newCluster]["stations"] = JSON(remainStats)
                        clusterInfo[newCluster]["start"] = JSON(stationRouting.getStartStat(statList: remainStats))

                        // Update cluster info
                        clusterInfo[nextCluster]["visited"] = true
                        nextClusterVisitPath.removeSubrange((i+1)...)
                        print("Visit next cluster on", terminator: "")
                        VisitLog.dumpPath(path: nextClusterVisitPath)
                        visitPath.append(contentsOf: nextClusterVisitPath)
                        preStat = log.station
                        break
                    }
                }
            }else {
                // Add next cluster visited path
                print("Go to cluster \(nextCluster)")
                clusterInfo[nextCluster]["visited"] = true
                visitPath.append(contentsOf: nextClusterVisitPath)
                preStat = nextClusterLastVisitLog.station
            }

            VisitLog.dumpPath(path: visitPath)

            // Reset path value when done today
            if visitedAll(jsonObj: clusterInfo) || (nextClusterFinishTime > workingTime) {
                print("----- Day \(day) done -----")
                print()
                preStat = startStat
                visitPath = [VisitLog(stat: startStat, timestamp: startTime, isRevisit: false)]
                day += 1
                stationRouting.resetRepeatTime()
                if visitedAll(jsonObj: clusterInfo) {
                    break
                }
                //print(clusterInfo)
            }
        }
        return Dictionary()
    }

    func visitedAll(jsonObj: JSON) -> Bool{
        for (k, _) in jsonObj{
            //var tmp = jsonObj[k]["visited"]
            //print(tmp)
            if jsonObj[k]["visited"] == false {
                //print("\(k) hasn't visited")
                return false
            }
        }
        print("All clusters has been visited")
        return true
    }

    func resetVisitedStatus(jsonObj: JSON) -> JSON{
        var jsonObjVisit: JSON = jsonObj
        for (k, _) in jsonObj{
            jsonObjVisit[k]["visited"] = false
        }
        //print(jsonObjVisit)
        return jsonObjVisit
    }
}
