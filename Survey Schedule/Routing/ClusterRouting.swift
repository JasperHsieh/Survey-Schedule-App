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
    /// True, if debugging message shows
    let Debug = false

    /// The new cluster start id
    var clusterStartId = 100

    /// The working time per day in seconds
    var workingTime: Int

    /// StationRouting object
    let stationRouting: StationRouting

    init(clusterInfo: JSON, workingTime: Int){
        //self.clusterInfo = clusterInfo
        self.workingTime = workingTime * 60 * 60
        //self.dataUtil = DataUtil()
        self.stationRouting = StationRouting()
    }

    /**
    Insert a cluster in the front of the schedule
    - Parameters:
        - clusterInfo: A JSON object represetn the clusters
        - workingHour: A time interval in hour to limit the routing per day
        - currentStat: A station name that current at
    - Returns: An new schedule

     Todo: Replace workingHour with array of workingHours. The workingHour could be different dpends on day
    */
    func getCompleteSchedule(info clusterInfo: JSON, workingHour: Int, currentStat: String) -> [[[VisitLog]]]{
        //let statInfo = DataUtil.statInfo
        //var clusterVisit = DataUtil.clusterInfo!
        var clusterVisit = resetVisitedStatus(jsonObj: clusterInfo)
        let workingTime = workingHour * 60 * 60

        var day = 1
        let startTime = 0
        var preStat = currentStat
        // Check the station isRevisit status while currentStat != CS25
        var visitPath: [VisitLog] = [VisitLog(stat: preStat, timestamp: startTime, isRevisit: false)]
        var daySchedule: [[VisitLog]] = []
        var schedule: [[[VisitLog]]] = []

        daySchedule.append(visitPath)

        if(Debug) {print("getNextDaySchedule \(workingTime)")}

        while true {

            // choose the closest cluster from preStat
            var nextCluster = "-1"
            var minTime = Int.max
            //print(clusterVisit)
            for (cluster, _) in clusterVisit {
                if !clusterVisit[cluster]["visited"].bool! {
                    //print("Checking cluster \(cluster)")
                    let travelTime = getStatsTravelTime(stat1: preStat, stat2: clusterVisit[cluster]["start"].string!)
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
            if(Debug) {print()}
            if(Debug) {print("*** Checking closest cluster \(nextCluster) ***")}
            //var nextClusterVisitPath = stationRouting.getVisitPath(statList: clusterVisit[nextCluster]["stations"].arrayObject as! [String], pathSoFar: visitPath)
            var nextClusterVisitPath = stationRouting.getVisitPath(statList: clusterVisit[nextCluster]["stations"].arrayObject as! [String], pathSoFar: visitPath)
            let nextClusterLastVisitLog = nextClusterVisitPath.last!
            let nextClusterFinishTime = nextClusterLastVisitLog.timestamp + getStatsTravelTime(stat1: nextClusterLastVisitLog.station, stat2: BaseStation)

            if nextClusterFinishTime > workingTime {
                // Exceed workingTime today, cut cluster
                if(Debug) {print("Exceed workingTime limit, cut cluster")}
                for i in (0..<nextClusterVisitPath.count).reversed() {
                    let log = nextClusterVisitPath[i]
                    if log.isRevisit {
                        if(Debug) {print("Ignore repeat station")}
                        continue
                    }
                    let timeToFinish = log.timestamp + getStatsTravelTime(stat1: log.station, stat2: BaseStation)
                    //print("Checking \()")
                    if(Debug) {print("Checking last station \(log.station) \(timeToFinish)")}
                    if timeToFinish < workingTime {
                        // Found availabe stations, form new cluster from left stations
                        if(Debug) {print("Cut cluster")}
                        let newCluster = String(clusterStartId)

                        clusterStartId += 1
                        clusterVisit[newCluster] = JSON()
                        clusterVisit[newCluster]["visited"] = false

                        var remainStats: [String] = []
                        for visitLog in Array(nextClusterVisitPath[(i+1)...]) {
                            remainStats.append(visitLog.station)
                        }

                        if(Debug) { print("RemainStats: \(remainStats)")}
                        clusterVisit[newCluster]["stations"] = JSON(remainStats)
                        clusterVisit[newCluster]["start"] = JSON(stationRouting.getStartStat(statList: remainStats))

                        // Update cluster info
                        clusterVisit[nextCluster]["visited"] = true
                        nextClusterVisitPath.removeSubrange((i+1)...)

                        if(Debug) {print("Visit next cluster on", terminator: "")}
                        if(Debug) {VisitLog.dumpPath(path: nextClusterVisitPath)}

                        visitPath.append(contentsOf: nextClusterVisitPath)
                        daySchedule.append(nextClusterVisitPath)
                        preStat = log.station
                        break
                    }
                }
            }else {
                // Add next cluster visited path
                if(Debug) {print("Go to cluster \(nextCluster)")}
                clusterVisit[nextCluster]["visited"] = true
                visitPath.append(contentsOf: nextClusterVisitPath)
                daySchedule.append(nextClusterVisitPath)
                preStat = nextClusterLastVisitLog.station
            }

            if(Debug) {VisitLog.dumpPath(path: visitPath)}

            // Reset path value when done today
            if visitedAll(jsonObj: clusterVisit) || (nextClusterFinishTime > workingTime) {
                if(Debug) {print("----- Day \(day) done -----")}
                if(Debug) {VisitLog.dumpPath(path: visitPath)}
                if(Debug) {print()}

                //scheduleDic[day] = visitPath
                schedule.append(daySchedule)

                preStat = BaseStation
                visitPath = [VisitLog(stat: BaseStation, timestamp: startTime, isRevisit: false)]
                daySchedule = []
                daySchedule.append(visitPath)
                day += 1
                stationRouting.resetRepeatTime()
                if visitedAll(jsonObj: clusterVisit) {
                    break
                }
                //print(clusterVisit)
            }
        }
        //VisitLog.dumpMasterSchedule(schedule: schedule)
        return schedule
    }

    /**
    Check all clusters have been visited
    - Parameters:
        - jsonObj: A JSON object represetn the clusters
    - Returns: true, if all clusters have been visited
    */
    func visitedAll(jsonObj: JSON) -> Bool{
        for (k, _) in jsonObj{
            //var tmp = jsonObj[k]["visited"]
            //print(tmp)
            if jsonObj[k]["visited"] == false {
                //print("\(k) hasn't visited")
                return false
            }
        }
        if(Debug) {print("All clusters has been visited")}
        return true
    }

    /**
    Set all cluster unvisited
    - Parameters:
        - jsonObj: A JSON object represetn the clusters
    - Returns: A JSON object represents the clusters with the visited value set false
    */
    func resetVisitedStatus(jsonObj: JSON) -> JSON{
        var jsonObjVisit: JSON = jsonObj
        for (k, _) in jsonObj{
            jsonObjVisit[k]["visited"] = false
        }
        //print(jsonObjVisit)
        return jsonObjVisit
    }
}
