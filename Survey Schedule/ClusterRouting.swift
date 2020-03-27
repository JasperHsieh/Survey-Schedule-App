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
        var visitPath: [VisitLog] = [VisitLog(stat: preStat, timestamp: startTime)]

        //while !visitedAll(jsonObj: clusterInfo){
        while true {
            // choose the closest cluster
            var nextCluster = "-1"
            var minTime = -1
            for (cluster, _) in clusterInfo {
                if !clusterInfo[cluster]["visited"].bool! {
                    let travelTime = dataUtil.getStatsTravelTime(stat1: preStat, stat2: clusterInfo[cluster]["start"].string!)
                    if travelTime < minTime {
                        minTime = travelTime
                        nextCluster = cluster
                    }
                }
            }
            if nextCluster == "-1" {
                print("Something wrong wiht finding next cluster")
                break
            }

            // Check if we finish next cluster in time
            //print("*** Go to cluster \(nextCluster) ***")
            var nextClusterVisitPath = stationRouting.getVisitPath(statList: clusterInfo[nextCluster]["stations"].arrayObject as! [String], pathSoFar: visitPath)
            let nextClusterLastVisitLog = nextClusterVisitPath.last!
            let nextClusterTime = nextClusterLastVisitLog.timestamp + dataUtil.getStatsTravelTime(stat1: nextClusterLastVisitLog.station, stat2: startStat)

            if nextClusterTime > workingTime {
                // Exceed workingTime today, cut cluster
                for (i, visitLog) in nextClusterVisitPath.reversed().enumerated() {
                    let timeToFinish = visitLog.timestamp + dataUtil.getStatsTravelTime(stat1: visitLog.station, stat2: startStat)
                    if timeToFinish < workingTime {
                        // Form new cluster from left stations
                        let newCluster = String(clusterStartId)
                        clusterStartId += 1
                        clusterInfo[newCluster] = JSON()
                        clusterInfo[newCluster]["visited"] = false
                        var remainStats: [String] = []
                        for visitLog in Array(nextClusterVisitPath[(i+1)...]) {
                            remainStats.append(visitLog.station)
                        }
                        clusterInfo[newCluster]["stations"] = JSON(remainStats)
                        clusterInfo[newCluster]["start"] = JSON(stationRouting.getStartStat(statList: remainStats))

                        // Update cluster info
                        clusterInfo[nextCluster]["visited"] = true
                        nextClusterVisitPath.removeSubrange((i+1)...)
                        visitPath.append(contentsOf: nextClusterVisitPath)
                        preStat = visitLog.station
                        break
                    }
                }
            }else {
                // Add next cluster visited path
                clusterInfo[nextCluster]["visited"] = true
                visitPath.append(contentsOf: nextClusterVisitPath)
                preStat = nextClusterLastVisitLog.station
            }

            // Reset path value when done today
            var visitedAllCluster = false
            if visitedAll(jsonObj: clusterInfo) {
                visitedAllCluster = true
            }
            if visitedAllCluster || (nextClusterTime > workingTime) {
                preStat = startStat
                visitPath = [VisitLog(stat: preStat, timestamp: startTime)]

                if visitedAllCluster {
                    break
                }
            }
        }
        return Dictionary()
    }

    func visitedAll(jsonObj: JSON) -> Bool{
        for (k, _) in jsonObj{
            //var tmp = jsonObj[k]["visited"]
            //print(tmp)
            if jsonObj[k]["visited"] == false {
                print("\(k) hasn't visited")
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
