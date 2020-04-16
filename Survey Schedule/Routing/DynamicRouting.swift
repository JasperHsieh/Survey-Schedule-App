//
//  DynamicRouting.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/22/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import SwiftDate
import SwiftyJSON

class DynamicRouting: ObservableObject{
    //let stations_everyday

    //let baseStat: String = "CS25"
    //static let N: Int = 2 // hours
    var preStation: String = BaseStation
    var nextVisitLog: VisitLog
    @Published var nextStation: String = "NASA"
    @Published var nextTravelTime: String = "00:00"

    var isStarted = false
    let dayLimit: Int = 8 // hours
    let defaultTime: Date
    var beginDate: Date
    var lastRepeatTime: Int

    // Stations list page
    @Published var stationsList: [Station]
    var stationListBackUp: [Bool] = []

    //var day: Int = 0
    //var preStat: String


    var masterSchedule: [[VisitLog]] = [[]]
    var clusterRouting: ClusterRouting
    var stationRouting: StationRouting

    var remainSchedule: [[VisitLog]] = [[]]
    var currentVisitPath: [VisitLog] = []
    var currentSchedule: [[VisitLog]] = [[]]

    init(){
        //statSequence = stations_everyday[Day] ?? []
        stationsList = getStationsList()
        clusterRouting = ClusterRouting(clusterInfo: clusterInfo!, workingTime: dayLimit)
        stationRouting = StationRouting()

        defaultTime = getTimeFromStr(time: "2020-01-01 09:00:00+00000")
        beginDate = getTimeFromStr(time: "2020-01-01 09:00:00+00000")
        lastRepeatTime = 0

        nextVisitLog = VisitLog(stat: BaseStation, timestamp: -1, isRevisit: false)
        //stationRouting.getMinTimePermutation(statList: clusterInfo!["1"]["stations"].arrayValue.map {$0.stringValue})
    }

    func makeScheduleInBackground() {
        DispatchQueue.global(qos: .userInitiated).async {
            //print("This is run on the background queue")
            self.makeRoutingSchedule(clusters: clusterInfo ?? JSON(), workintHour: WorkingHour, currentStat: BaseStation)
            DispatchQueue.main.async {
                //print("This is run on the main queue, after the previous code in outer block")
                self.remainSchedule = self.masterSchedule
                self.updateFirstStation()
            }
        }
    }

    func makeRoutingSchedule(clusters: JSON, workintHour: Int, currentStat: String){
        masterSchedule = clusterRouting.getCompleteSchedule(info: clusters, workingHour: workintHour, currentStat: currentStat)
    }

    func applyStationsChangeToSchedule() {
        let clusters = createClusters()
        print(clusters)
        masterSchedule = clusterRouting.getCompleteSchedule(info: clusters, workingHour: 8, currentStat: preStation)
    }

    func createClusters() -> JSON {
        var clustersJson = JSON()
        var tmpDic: [String: [String]] = [:]

        for station in stationsList {
            if station.isScheduled && !station.isVisited {
                let cluster = getCluster(station: station)
                let clusterExists = tmpDic[cluster] != nil
                if !clusterExists {
                    tmpDic[cluster] = []
                }
                tmpDic[cluster]!.append(station.name)
            }
        }

        for (cluster, stations) in tmpDic {
            //print("\(cluster) \(stations)")
            clustersJson[cluster] = JSON()
            clustersJson[cluster]["stations"] = JSON(stations)
            clustersJson[cluster]["start"] = JSON(stationRouting.getStartStat(statList: stations))
        }
        return clustersJson
    }

    func getCluster(station: Station) -> String {
        if statInfo![station.name].exists() {
            if statInfo![station.name]["cluster"].exists() {
                return statInfo![station.name]["cluster"].stringValue
            } else {
                print("station \(station.name) cluster not found in statInfo")
            }
        } else {
            print("station \(station.name) not found in statInfo")
        }
        return "Not Found"
    }

    func updateFirstStation() {
        if masterSchedule.isEmpty || masterSchedule[0].isEmpty {
            print("Master Schedule is empty")
            return
        }
        let nextVisitLog = masterSchedule[0][0]
        nextStation = nextVisitLog.station
    }

    func backupStationsSetting() {
        print("backupStationsSetting")
        stationListBackUp = []
        for station in stationsList {
            stationListBackUp.append(station.isScheduled)
        }
    }

    func isScheduledStationsChanged() -> Bool {
        for (i, station) in stationsList.enumerated() {
            if station.isScheduled != stationListBackUp[i] {
                print("station \(station.name) changed")
                return true
            }
        }
        return false
    }

    func setStationVisited(station: String) {
        var index: Int {
            stationsList.firstIndex(where: {$0.name == station})!
        }
        stationsList[index].isVisited = true
    }

    func HandleDoneAction(){
        print("[DR] HandleDoneAction")
        // Save preStation visit log
        let currentDate = getCurrentDate()
        let currentTime = getDiffInSec(start: beginDate, end: currentDate)
        print("[DR] currentDate \(currentDate)")
        //print("diff \(currentTime)")

        setStationVisited(station: nextVisitLog.station)
        if nextVisitLog.isRevisit {
            lastRepeatTime = currentTime
        }
        nextVisitLog.timestamp = currentTime
        currentVisitPath.append(nextVisitLog)

        removePreStation()

        if currentTime - lastRepeatTime > N {
            print("[DR] Time to revisit")
            if currentVisitPath.isEmpty {
                print("[DR] No visited stations")
            } else {
                var minTravelTime = Int.max
                var minVisitLog: VisitLog?

                for visitLog in currentVisitPath {
                    let curTravelTime = getStatsTravelTime(stat1: nextVisitLog.station, stat2: visitLog.station)
                    let timeSoFar = getDiffInSec(start: beginDate, end: currentDate)
                    if  curTravelTime < M && (timeSoFar + curTravelTime - visitLog.timestamp > N) && curTravelTime < minTravelTime {
                        minTravelTime = curTravelTime
                        minVisitLog = visitLog
                    }
                }
                if let visitLog = minVisitLog {
                    nextVisitLog = VisitLog(stat: visitLog.station, timestamp: -1, isRevisit: true)
                    nextStation = visitLog.station
                    nextTravelTime = getTravelTimeString(sec: minTravelTime)
                    // Check the next station is last in a cluster

                }
            }
        } else {
            print("[DR] Go to next station")
            nextStation = getFirstStation()
            print("[DR] nextStation \(nextStation)")
            let timeToNextStation = getStatsTravelTime(stat1: nextVisitLog.station, stat2: nextStation)
            nextTravelTime = getTravelTimeString(sec: timeToNextStation)
            nextVisitLog = VisitLog(stat: nextStation, timestamp: -1, isRevisit: false)
        }
    }

    func getFirstStation() -> String {
        if remainSchedule.isEmpty {
            print("remain Schedule is Empty")
            return "OMG"
        }
        let visitPath = remainSchedule[0]
        return visitPath[0].station
    }

    func removePreStation() {
        if remainSchedule.isEmpty {
            print("remain Schedule is Empty")
            return
        }
        // Remove first station
        print("[DR] removePreStation")
//        for day in remainSchedule {
//            VisitLog.dumpPath(path: day)
//            print()
//        }
        let visitPath = remainSchedule[0]
        var newVisitPath: [VisitLog] = []
        if visitPath.count > 1 {
            newVisitPath = Array(visitPath[1..<visitPath.count])
        }
        //VisitLog.dumpPath(path: newVisitPath)
        var newRemainSchedule: [[VisitLog]] = []
        for (i, _) in remainSchedule.enumerated() {
            if i == 0 {
                if !newVisitPath.isEmpty {
                    //print("[DR] add newVisitPath")
                    newRemainSchedule.append(newVisitPath)
                }
            } else {
                //print("[DR] add remainSchedule")
                newRemainSchedule.append(remainSchedule[i])
            }
        }
        remainSchedule = newRemainSchedule

//        for day in remainSchedule {
//            VisitLog.dumpPath(path: day)
//            print()
//            break
//        }

    }
}
