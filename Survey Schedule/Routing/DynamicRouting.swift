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


    var masterSchedule: [[[VisitLog]]] = []
    var clusterRouting: ClusterRouting
    var stationRouting: StationRouting

    var remainSchedule: [[[VisitLog]]] = [[]]
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
        let nextVisitLog = masterSchedule[0][0][0]
        nextStation = nextVisitLog.station

        removeFirstStation()
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
            stationsList.firstIndex(where: {$0.name == station}) ?? -1
        }
        if index != -1 {
            stationsList[index].isVisited = true
        }
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

        //removePreStation()

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
                if let minVisitLog = minVisitLog {
                    updateRevisitChangeInMasterSchedule(doneStation: nextVisitLog.station, revisitStation: minVisitLog.station)

                    nextVisitLog = VisitLog(stat: minVisitLog.station, timestamp: -1, isRevisit: true)
                    nextStation = minVisitLog.station
                    nextTravelTime = getTravelTimeString(sec: minTravelTime)
                    // Check the next station is last in a cluster

                }
            }
        } else {
            print("[DR] Go to next station")
            nextStation = getNextStation()
            print("[DR] nextStation \(nextStation)")
            let timeToNextStation = getStatsTravelTime(stat1: nextVisitLog.station, stat2: nextStation)
            nextTravelTime = getTravelTimeString(sec: timeToNextStation)
            nextVisitLog = VisitLog(stat: nextStation, timestamp: -1, isRevisit: false)
        }
        removeFirstStation()
    }

    func updateRevisitChangeInMasterSchedule(doneStation: String, revisitStation: String) {
        var stationsInCluster = getUnvisitedStationsInCluster(doneStation: doneStation)
        stationsInCluster.insert(revisitStation, at: 0)
        let newSequence = self.stationRouting.getMinTimePermutationWithStart(startStat: revisitStation, statList: stationsInCluster)
        let newRevisitSchedule = getRevisitClusterSchedule(from: newSequence)

        var newMasterSchedule: [[[VisitLog]]] = []
        var newDaySchedule: [[VisitLog]] = []
        let compareCluster = getNextCluster()
        var preCluster: [VisitLog] = []
        var found = false
        for daySchedule in masterSchedule {
            newDaySchedule = []
            for clusterSchedule in daySchedule {
                if isSameCluster(cluster1: clusterSchedule, cluster2: compareCluster) {
                    found = true
                    // Remove pre cluster from tmporary storage
                    if newDaySchedule.count > 0 {
                        newDaySchedule = Array(newDaySchedule[0..<daySchedule.count-1])
                    } else {
                        var lastDaySchedule = newMasterSchedule[newMasterSchedule.count-1]
                        newMasterSchedule.removeLast()
                        if lastDaySchedule.count != 1 {
                            lastDaySchedule.removeLast()
                            newMasterSchedule.append(lastDaySchedule)
                        }
                    }
                    // Assemble current cluster
                    for (i,visitLog) in preCluster.enumerated() {
                        if visitLog.station == doneStation {
                            newDaySchedule.append(Array(preCluster[0...i]))
                            break
                        }
                    }
                    newDaySchedule.append(newRevisitSchedule)

                }
                newDaySchedule.append(clusterSchedule)
                preCluster = clusterSchedule
            }
            newMasterSchedule.append(newDaySchedule)
        }

        // Revisit in last cluster
        if !found {
            newMasterSchedule.removeLast()
            newDaySchedule.removeLast()
            for (i,visitLog) in preCluster.enumerated() {
                if visitLog.station == doneStation {
                    newDaySchedule.append(Array(preCluster[0...i]))
                    break
                }
            }
            newDaySchedule.append(newRevisitSchedule)
            newMasterSchedule.append(newDaySchedule)
        }
        masterSchedule = newMasterSchedule
    }

    func isSameCluster(cluster1: [VisitLog], cluster2: [VisitLog]) -> Bool{
        if cluster1.count != cluster2.count {
            return false
        }
        for (vg1, vg2) in zip(cluster1, cluster2) {
            if vg1.station != vg2.station {
                return false
            }
        }
        return true
    }

    func getRevisitClusterSchedule(from stations: [String]) -> [VisitLog] {
        var visitPath: [VisitLog] = []
        for (i,station) in stations.enumerated() {
            // TODO: calculate timestamp
            if i == 0 {
                visitPath.append(VisitLog(stat: station, timestamp: 0, isRevisit: true))
            } else{
                visitPath.append(VisitLog(stat: station, timestamp: 0, isRevisit: false))
            }
        }
        return visitPath
    }

    func getUnvisitedStationsInCluster(doneStation: String) -> [String]{
        if remainSchedule.isEmpty {
            print("[DR] remain Schedule is Empty")
            return []
        }
        let daySchedule = remainSchedule[0]
        if daySchedule.count > 0 {
            var stations: [String] = []
            for visitLog in daySchedule[0] {
                if visitLog.station != doneStation && !visitLog.isRevisit {
                    stations.append(visitLog.station)
                }
                return stations
            }
        }
        print("[DR] day schedule is empty")
        return []
    }

    func getNextCluster() -> [VisitLog] {
        if remainSchedule.isEmpty {
            print("[DR] remain Schedule is Empty")
            return []
        }
        let daySchedule = remainSchedule[0]
        if daySchedule.count > 1 {
            return daySchedule[1]
        }
        return []
    }

    func getNextStation() -> String {
        if remainSchedule.isEmpty {
            print("[DR] remain Schedule is Empty")
            return "OMG"
        }
        let visitPath = remainSchedule[0][0]
        // Skip revisit station?
        return visitPath[0].station
    }

    func removeFirstStation() {
        if remainSchedule.isEmpty {
            print("[DR] remain Schedule is Empty")
            return
        }
        // Remove first station
        print("[DR] removePreStation")
        //VisitLog.dumpMasterSchedule(schedule: remainSchedule)

        let daySchedule = remainSchedule[0]
        let clusterSchedule = daySchedule[0]

        var newRemainSchedule: [[[VisitLog]]] = []
        var newDaySchedule: [[VisitLog]] = []
        var newClusterSchedule: [VisitLog] = []

        if clusterSchedule.count >= 2 {
            newClusterSchedule = Array(clusterSchedule[1..<clusterSchedule.count])
        }

        if !newClusterSchedule.isEmpty {
            newDaySchedule.append(newClusterSchedule)
        }
        for (i, cluster) in daySchedule.enumerated() {
            if i > 0 {
                newDaySchedule.append(cluster)
            }
        }

        if !newDaySchedule.isEmpty {
            newRemainSchedule.append(newDaySchedule)
        }
        for (i, day) in remainSchedule.enumerated() {
            if i > 0 {
                newRemainSchedule.append(day)
            }
        }
        remainSchedule = newRemainSchedule
        //VisitLog.dumpMasterSchedule(schedule: remainSchedule)
    }
}
