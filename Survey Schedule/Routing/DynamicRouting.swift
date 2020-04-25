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
    //var preStation: String = BaseStation
    var preVisitLog: VisitLog
    var nextVisitLog: VisitLog
    @Published var nextStation: String = "NASA"
    @Published var nextTravelTime: String = "00:00"
    @Published var doneLoading: Bool = true
    //@Published var scheduleCount: Int = 0

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
    //var currentSchedule: [[VisitLog]] = [[]]

    init(){
        //statSequence = stations_everyday[Day] ?? []
        stationsList = getStationsList()
        clusterRouting = ClusterRouting(clusterInfo: clusterInfo!, workingTime: dayLimit)
        stationRouting = StationRouting()

        defaultTime = getTimeFromStr(time: "2020-01-01 09:00:00+00000")
        beginDate = getTimeFromStr(time: "2020-01-01 09:00:00+00000")
        lastRepeatTime = 0

        preVisitLog = VisitLog(stat: BaseStation, timestamp: -1, isRevisit: false)
        nextVisitLog = preVisitLog
        //stationRouting.getMinTimePermutation(statList: clusterInfo!["1"]["stations"].arrayValue.map {$0.stringValue})
    }

    func makeScheduleInBackground() {
        DispatchQueue.global(qos: .userInitiated).async {
            //print("This is run on the background queue")
            self.makeRoutingSchedule(clusters: clusterInfo ?? JSON(), workintHour: WorkingHour, currentStat: BaseStation)
            DispatchQueue.main.async {
                //print("This is run on the main queue, after the previous code in outer block")
                self.remainSchedule = self.masterSchedule
                self.setNextVisitLog(station: self.getNextStation(), isRevisit: false)
                //self.updateNextStation()
                //self.removeFirstStation()
            }
        }
    }

    func makeRoutingSchedule(clusters: JSON, workintHour: Int, currentStat: String){
        masterSchedule = clusterRouting.getCompleteSchedule(info: clusters, workingHour: workintHour, currentStat: currentStat)
        indexingSchedule()
    }

    func applyStationsChange() {
        print("[DR] Applying change..., preVisitLog: \(preVisitLog.station)")
        doneLoading = false
        DispatchQueue.global(qos: .userInitiated).async {
            let clusters = self.createClusters()
            print(clusters)
            VisitLog.dumpDaySchedule(daySchedule: self.remainSchedule[0])
            self.remainSchedule = self.clusterRouting.getCompleteSchedule(info: clusters, workingHour: 8, currentStat: self.preVisitLog.station)
            self.removeFirstStation()
    //        masterSchedule = mergeSchedule(remainSchedule: remainSchedule)
            self.masterSchedule = self.mergeSchedule()
    //        masterSchedule = indexVisitLog(schedule: masterSchedule)
            self.indexingSchedule()
            self.setNextVisitLog(station: self.getNextStation(), isRevisit: false)
            //nextVisitLog = VisitLog(stat: getNextStation(), timestamp: -1, isRevisit: false)
            print("[DR] After applying")
            VisitLog.dumpDaySchedule(daySchedule: self.remainSchedule[0])
            //sleep(LoadingView.delay)
            DispatchQueue.main.async {
                self.doneLoading = true
            }
        }
    }

    func setNextVisitLog(station: String, isRevisit: Bool) {
        DispatchQueue.main.async {
            self.nextVisitLog = VisitLog(stat: station, timestamp: -1, isRevisit: isRevisit)
            self.nextStation = station
            let timeToNextStation = getStatsTravelTime(stat1: self.preVisitLog.station, stat2: self.nextStation)
            self.nextTravelTime = getTravelTimeString(sec: timeToNextStation)
        }
    }

    func mergeSchedule() -> [[[VisitLog]]] {
        print("[DR] mergeSchedule")
        //VisitLog.dumpDaySchedule(daySchedule: remainSchedule[0])
        //print("[DR] before masterSchedule")
        //VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
        var newMasterSchedule = remainSchedule
        for day in 0..<newMasterSchedule.count {
            for cluster in 0..<newMasterSchedule[day].count {
                newMasterSchedule[day][cluster] = currentVisitPath + newMasterSchedule[day][cluster]
                return newMasterSchedule
            }
        }
//        print("[DR] after mergeSchedule:")
//        print("[DR] after remainSchedule")
//        VisitLog.dumpDaySchedule(daySchedule: remainSchedule[0])
//        print("[DR] after masterSchedule")
//        VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
        return newMasterSchedule
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

//    func updateNextStation() {
//        if masterSchedule.isEmpty || masterSchedule[0].isEmpty {
//            print("Master Schedule is empty")
//            return
//        }
//        var preStation = BaseStation
//        for daySchedule in masterSchedule {
//            for clusterSchedule in daySchedule {
//                for visitLog in clusterSchedule {
//                    var index: Int {
//                        stationsList.firstIndex(where: {$0.name == visitLog.station}) ?? -1
//                    }
//                    if !stationsList[index].isVisited &&  stationsList[index].isScheduled {
//                        nextStation = stationsList[index].name
//                        let timeToNextStation = getStatsTravelTime(stat1: preStation, stat2: nextStation)
//                        nextTravelTime = getTravelTimeString(sec: timeToNextStation)
//                        return
//                    }
//                    preStation = stationsList[index].name
//                }
//            }
//        }
//    }

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

    func setPreStationVisited() {
        DispatchQueue.main.async { // update visitedCount in main thread
            let station = self.preVisitLog.station
            print("[DR] set \(station) visited")
            var index: Int {
                self.stationsList.firstIndex(where: {$0.name == station}) ?? -1
            }
            if index != -1 {
                self.stationsList[index].isVisited = true
                //self.scheduleCount += 1
            }
        }
    }

    func getStationIndex(station: String) -> Int {
        let index = stationsList.firstIndex(where: {$0.name == station}) ?? -1
        return index
    }

    func HandleDoneAction(){
        print("[DR] HandleDoneAction \(nextVisitLog.station)")
        // Save preStation visit log
        let currentDate = getCurrentDate()
        var timeSoFar = getDiffInSec(start: beginDate, end: currentDate)
        print("[DR] currentDate \(currentDate)")
        //print("diff \(currentTime)")

        preVisitLog = nextVisitLog
        setPreStationVisited()

        if preVisitLog.station == "RE4" {
            timeSoFar += 2*60*60
        }

        if preVisitLog.isRevisit {
            lastRepeatTime = timeSoFar
        }
        preVisitLog.didVisit = true
        preVisitLog.timestamp = timeSoFar
        currentVisitPath.append(preVisitLog)

        if timeSoFar - lastRepeatTime > N {
            print("[DR] Time to revisit")
            if currentVisitPath.isEmpty {
                print("[DR] No visited stations")
            } else {
                var minTravelTime = Int.max
                var minVisitLog: VisitLog?

                for visitLog in currentVisitPath {
                    if !visitLog.didVisit {
                        continue
                    }
                    let curTravelTime = getStatsTravelTime(stat1: preVisitLog.station, stat2: visitLog.station)
                    //print("[DR] \(preVisitLog.station)<->\(visitLog.station) \(curTravelTime)")
                    //let timeSoFar = getDiffInSec(start: beginDate, end: currentDate)
                    //let tmp  = timeSoFar + curTravelTime - visitLog.timestamp
                    //print("[DR] tmp \(tmp)")
                    if  curTravelTime < M && (timeSoFar + curTravelTime - visitLog.timestamp > N) && curTravelTime < minTravelTime {
                        minTravelTime = curTravelTime
                        minVisitLog = visitLog
                    }
                }
                if let minVisitLog = minVisitLog {
                    print("[DR] Revisit \(minVisitLog.station)")
                    updateRevisitChangeInMasterSchedule(doneStation: preVisitLog.station, revisitStation: minVisitLog.station)
                    setNextVisitLog(station: minVisitLog.station, isRevisit: true)
                    //nextVisitLog = VisitLog(stat: minVisitLog.station, timestamp: -1, isRevisit: true)
//                    let index = getStationIndex(station: minVisitLog.station)
//                    stationsList[index].shouldRevisit = true

                } else {
                    print("[DR] No valid revisit station. T_T")
                }
            }
        } else {
            //print("[DR] Go to next station")
            //let timeToNextStation = getStatsTravelTime(stat1: nextVisitLog.station, stat2: nextStation)
            //nextTravelTime = getTravelTimeString(sec: timeToNextStation)
            removeFirstStation()
            setNextVisitLog(station: getNextStation(), isRevisit: false)
            //nextVisitLog = VisitLog(stat: getNextStation(), timestamp: -1, isRevisit: false)
            print("[DR] nextStation \(nextVisitLog.station)")
        }
        //VisitLog.dumpMasterSchedule(schedule: remainSchedule)
        //VisitLog.dumpDaySchedule(daySchedule: remainSchedule[0])
    }

//    func updateRevisitChange(doneStation: String, revisitStation: String) {
//        var stationsInCluster = getUnvisitedStationsInCluster(doneStation: doneStation)
//        stationsInCluster.insert(revisitStation, at: 0)
//    }

    func removeRevisit() {

    }

    func updateRevisitChangeInMasterSchedule(doneStation: String, revisitStation: String) {
        var stationsInCluster = getUnvisitedStationsInCluster(doneStation: doneStation)
        stationsInCluster.insert(revisitStation, at: 0)
        let newSequence = self.stationRouting.getMinTimePermutationWithStart(startStat: revisitStation, statList: stationsInCluster)
        let newRevisitClusterSchedule = getRevisitClusterSchedule(from: newSequence)

        //print("[DR] stationsInCluster = \(stationsInCluster)")
        print("[DR] newSequence = \(newSequence)")
        print("[DR] newRevisitSchedule = \(newRevisitClusterSchedule)")

        // Update remain schedule
        remainSchedule = removeFirstCluster(schedule: remainSchedule)
        remainSchedule = insertFirstCluster(clusterSchedule: newRevisitClusterSchedule, schedule: remainSchedule)

        // Update master schedule
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
                        newDaySchedule = Array(newDaySchedule[0..<newDaySchedule.count-1])
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
                    newDaySchedule.append(newRevisitClusterSchedule)

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
            newDaySchedule.append(newRevisitClusterSchedule)
            newMasterSchedule.append(newDaySchedule)
        }
        masterSchedule = newMasterSchedule
        indexingSchedule()
    }

    func removeFirstCluster(schedule: [[[VisitLog]]]) -> [[[VisitLog]]] {
        if schedule.isEmpty {
            print("[DR] schedule is Empty")
            return []
        }
        let daySchedule = schedule[0]
        var newSchedule: [[[VisitLog]]] = []

        if schedule.count > 1{
            newSchedule = Array(schedule[1..<schedule.count])
        }

        if daySchedule.count > 1 {
            let newDaySchedule = Array(daySchedule[1..<daySchedule.count])
            newSchedule.insert(newDaySchedule, at: 0)
        }

        return newSchedule
    }

    func insertFirstCluster(clusterSchedule: [VisitLog], schedule: [[[VisitLog]]]) -> [[[VisitLog]]] {
        var newSchedule: [[[VisitLog]]] = []
        var newDaySchedule: [[VisitLog]] = []

        if schedule.count > 0 {
            newDaySchedule = schedule[0]
        }
        if schedule.count > 1{
            newSchedule = Array(schedule[1..<schedule.count])
        }

        newDaySchedule.insert(clusterSchedule, at: 0)
        newSchedule.insert(newDaySchedule, at: 0)
        return newSchedule
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
//        print("[DR] first cluster ", terminator: "")
//        VisitLog.dumpPath(path: daySchedule[0])
        if daySchedule.count > 0 {
            var stations: [String] = []
            for visitLog in daySchedule[0] {
                if visitLog.station != doneStation && !visitLog.isRevisit {
                    stations.append(visitLog.station)
                }
            }
            return stations
        }
        print("[DR] day schedule is empty")
        return []
    }

    func indexingSchedule() {
        var i = 0
        for day in 0..<masterSchedule.count {
            for cluster in 0..<masterSchedule[day].count {
                for visitLog in 0..<masterSchedule[day][cluster].count {
                    masterSchedule[day][cluster][visitLog].index = i
                    i += 1
                }
            }
        }
        print("[DR] indexVisitLog")
        //VisitLog.dumpMasterSchedule(schedule: newSchedule)
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
//        for day in remainSchedule {
//            for cluster in day {
//                for visitLog in cluster {
//                    if visitLog.isRevisit {
//
//                        continue
//                    }
//                    return
//                }
//            }
//        }
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

    func handleSkipNextStation() {
        print("[DR] Skip \(nextVisitLog.station)")
        doneLoading = false
        currentVisitPath.append(nextVisitLog)
        let index = getStationIndex(station: nextStation)
        stationsList[index].isScheduled = false
        removeFirstStation()
        setNextVisitLog(station: getNextStation(), isRevisit: false)
        //self.scheduleCount += 1
        doneLoading = true
    }

    func isStationScheduled(station: String) -> Bool{
        let index = getStationIndex(station: station)
        return stationsList[index].isScheduled
    }

    func handleEndSurvey() {
        setNextVisitLog(station: BaseStation, isRevisit: false)
        //doneLoading = false
        DispatchQueue.global(qos: .userInitiated).async {
            let clusters = self.createClusters()
            print("[DR] Creating shcedule for tomorrow")
            self.remainSchedule = self.clusterRouting.getCompleteSchedule(info: clusters, workingHour: 8, currentStat: BaseStation)
            self.masterSchedule = self.remainSchedule
            print("[DR] Done creating shcedule for tomorrow")
            DispatchQueue.main.async {
                //self.doneLoading = true
            }
        }
    }
}
