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
    var nextIdx: StatIndex
    @Published var nextStation: String = "NASA"
    @Published var nextTravelTime: String = "00:00"
    @Published var doneLoading: Bool = true
    //@Published var scheduleCount: Int = 0

    var isStarted = false
    let dayLimit: Int = 8 // hours
    let defaultTime: Date
    var beginDate: Date
    var lastRepeatTime: Int
    let today: Int

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
        nextIdx = (0, 0, 0)

        today = 0
        //stationRouting.getMinTimePermutation(statList: clusterInfo!["1"]["stations"].arrayValue.map {$0.stringValue})
    }

    func reset() {
        print("[DR] reset")
        beginDate = getCurrentDate()
        lastRepeatTime = 0
        preVisitLog.date = beginDate
        applyTimestamp(day: 0, startDate: beginDate)
        VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
    }

    func makeInitialSchedule() {
        DispatchQueue.global(qos: .userInitiated).async {
            //print("This is run on the background queue")
            //self.makeRoutingSchedule(clusters: clusterInfo ?? JSON(), workintHour: WorkingHour, currentStat: BaseStation)
            self.masterSchedule = self.clusterRouting.getCompleteSchedule(info: clusterInfo ?? JSON(), workingHour: WorkingHour, currentStat: BaseStation)
            self.indexingSchedule()
            self.applyInitialTimestamp()

            VisitLog.dumpDaySchedule(daySchedule: self.masterSchedule[0])
            DispatchQueue.main.async {
                //self.remainSchedule = self.masterSchedule
                self.setNextVisitLog(isRevisit: false)
                self.setNextStation()
                //self.updateNextStation()
                //self.removeFirstStation()
            }
        }
    }

//    func makeRoutingSchedule(clusters: JSON, workintHour: Int, currentStat: String){
//        masterSchedule = clusterRouting.getCompleteSchedule(info: clusters, workingHour: workintHour, currentStat: currentStat)
//        indexingSchedule()
//    }

    func mergeSchedule(updatedSchedule: [[[VisitLog]]]) {
        var updatedSchedule = updatedSchedule
        updatedSchedule[0].insert(currentVisitPath, at: 0)
        masterSchedule = updatedSchedule
    }

    func applyStationsChange() {
        print("[DR] Applying change..., preVisitLog: \(preVisitLog.station)")
        doneLoading = false
        DispatchQueue.global(qos: .userInitiated).async {
            let clusters = self.createClusters()
            print(clusters)
            //VisitLog.dumpDaySchedule(daySchedule: self.masterSchedule[0])

            var updatedSchedule = self.clusterRouting.getCompleteSchedule(info: clusters, workingHour: 8, currentStat: self.preVisitLog.station)
            updatedSchedule = self.removeFirstStation(schedule: updatedSchedule)

            //self.masterSchedule = self.mergeSchedule()
            self.mergeSchedule(updatedSchedule: updatedSchedule)
            self.indexingSchedule()
            self.setNextVisitLog(isRevisit: false)
            //nextVisitLog = VisitLog(stat: getNextStation(), timestamp: -1, isRevisit: false)
            print("[DR] After applying")
            VisitLog.dumpDaySchedule(daySchedule: self.masterSchedule[0])
            //sleep(LoadingView.delay)
            DispatchQueue.main.async {
                self.doneLoading = true
            }
        }
    }

    func removeFirstStation(schedule: [[[VisitLog]]]) -> [[[VisitLog]]] {
        if schedule.isEmpty {
            print("[DR] remain Schedule is Empty")
            return []
        }
        //print("[DR] removeFirstStation before")
        //VisitLog.dumpDaySchedule(daySchedule: schedule[0])
        var schedule = schedule
        let daySchedule = schedule[0]
        let clusterSchedule = daySchedule[0]

        if clusterSchedule.count <= 1 {
            //schedule[0][0].remove(at: 0)
            //print("[DR] clusterSchedule <= 1")
            schedule[0].remove(at: 0)
        } else {
            //print("[DR] clusterSchedule >= 2")
            schedule[0][0] = Array(schedule[0][0][1..<schedule[0][0].count])
        }
        //print("[DR] removeFirstStation after")
        //VisitLog.dumpDaySchedule(daySchedule: schedule[0])
        return schedule
    }

    func setNextVisitLog(isRevisit: Bool) {
            print("[DR] setNextVisitLog")
            let statIdx = self.getNextVisitLog()
            //self.nextVisitLog = VisitLog(stat: station, timestamp: -1, isRevisit: isRevisit)
            self.nextVisitLog = self.masterSchedule[statIdx.day][statIdx.cluster][statIdx.station]
            self.nextVisitLog.isRevisit = isRevisit
    }

    func setNextStation() {
        DispatchQueue.main.async {
            print("[DR] setNextStation \(self.nextVisitLog.station)")
            self.nextStation = self.nextVisitLog.station
            let timeToNextStation = getStatsTravelTime(stat1: self.preVisitLog.station, stat2: self.nextStation)
            self.nextTravelTime = getTravelTimeString(sec: timeToNextStation)
        }
    }

//    func mergeSchedule() -> [[[VisitLog]]] {
//        print("[DR] mergeSchedule")
//        //VisitLog.dumpDaySchedule(daySchedule: remainSchedule[0])
//        //print("[DR] before masterSchedule")
//        //VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
//        var newMasterSchedule = remainSchedule
//        for day in 0..<newMasterSchedule.count {
//            for cluster in 0..<newMasterSchedule[day].count {
//                newMasterSchedule[day][cluster] = currentVisitPath + newMasterSchedule[day][cluster]
//                return newMasterSchedule
//            }
//        }
////        print("[DR] after mergeSchedule:")
////        print("[DR] after remainSchedule")
////        VisitLog.dumpDaySchedule(daySchedule: remainSchedule[0])
////        print("[DR] after masterSchedule")
////        VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
//        return newMasterSchedule
//    }

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

    func doneVisitStation() {
        doneLoading = false
        DispatchQueue.global(qos: .userInitiated).async {
            sleep(LoadingView.delay)
            self.HandleDoneAction()
            DispatchQueue.main.async {
                self.doneLoading = true
            }
        }
    }

    func updateTimestamp(offset: DateComponents) {
        print("[DR] updateTimestamp \(preVisitLog.date)")
        print("[DR] \(masterSchedule[nextIdx.day][nextIdx.cluster][nextIdx.station].station)")
//        for day in nextIdx.day..<masterSchedule.count {
//            for cluster in nextIdx.cluster..<masterSchedule[day].count {
//                for log in nextIdx.station..<masterSchedule[day][cluster].count {
//                    masterSchedule[day][cluster][log].date = offset + masterSchedule[day][cluster][log].date
//                }
//            }
//        }
        for cluster in 0..<masterSchedule[today].count {
            for log in 0..<masterSchedule[today][cluster].count {
                if today < nextIdx.day  || (today == nextIdx.day && cluster < nextIdx.cluster) || (today == nextIdx.day && cluster == nextIdx.cluster && log < nextIdx.station) {
                        continue
                    }
                    masterSchedule[today][cluster][log].date = offset + masterSchedule[today][cluster][log].date
            }
        }
    }

    func HandleDoneAction(){
        print("[DR] HandleDoneAction \(nextVisitLog.station)")
        // Save preStation visit log
        let currentDate = getCurrentDate()
        var timeSoFar = getDiffInSec(start: beginDate, end: currentDate)
        let simulateRevisit = false
        print("[DR] currentDate \(currentDate)")
        //print("diff \(currentTime)")

        preVisitLog = nextVisitLog
        setPreStationVisited()

        if simulateRevisit && preVisitLog.station == "RE4" {
            timeSoFar += 2*60*60
        }

        if preVisitLog.isRevisit {
            lastRepeatTime = timeSoFar
        }
        preVisitLog.didVisit = true
        //preVisitLog.timestamp = timeSoFar

        let timeOffset = (currentDate - preVisitLog.date)
        print("[DR] offset \(timeOffset) \(currentDate) \(preVisitLog.date)")
        preVisitLog.date = currentDate

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
                    //updateRevisitChangeInMasterSchedule(doneStation: preVisitLog.station, revisitStation: minVisitLog.station)
                    updateRevisitChange(doneStation: preVisitLog.station, revisitStation: minVisitLog.station)
                    setNextVisitLog(isRevisit: true)
                    //nextVisitLog = VisitLog(stat: minVisitLog.station, timestamp: -1, isRevisit: true)
//                    let index = getStationIndex(station: minVisitLog.station)
//                    stationsList[index].shouldRevisit = true

                } else {
                    print("[DR] No valid revisit station. T_T")
                }
            }
        } else {
            //print("[DR] Go to next station")
            //removeFirstStation()
            setNextVisitLog(isRevisit: false)
        }
        //VisitLog.dumpMasterSchedule(schedule: remainSchedule)
        //VisitLog.dumpDaySchedule(daySchedule: remainSchedule[0])
        //VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
        updateTimestamp(offset: timeOffset)
        //setNextStation()
        VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
        setNextStation()
    }

//    func updateRevisitChange(doneStation: String, revisitStation: String) {
//        var stationsInCluster = getUnvisitedStationsInCluster(doneStation: doneStation)
//        stationsInCluster.insert(revisitStation, at: 0)
//    }

    func removeRevisit() {

    }

    func getUnvisitedStationsInCluster() -> [String]{
        var stations:Set = Set<String>()
        let cluster = masterSchedule[nextIdx.day][nextIdx.cluster]
        for i in nextIdx.station+1..<cluster.count {
            stations.insert(cluster[i].station)
        }
        return Array(stations)
    }

    func updateRevisitChange(doneStation: String, revisitStation: String) {
        var stationsInCluster = getUnvisitedStationsInCluster()
        stationsInCluster.insert(revisitStation, at: 0)
        let newSequence = self.stationRouting.getMinTimePermutationWithStart(startStat: revisitStation, statList: stationsInCluster)
        let newRevisitClusterSchedule = getRevisitClusterSchedule(from: newSequence)
        print("[DR] stationsInCluster:\(stationsInCluster)")
        print("[DR] newSequence:\(newSequence)")
        var updatedSchedule = Array(masterSchedule[nextIdx.day][nextIdx.cluster][0...nextIdx.station])
        updatedSchedule.append(contentsOf: newRevisitClusterSchedule)

        masterSchedule[nextIdx.day][nextIdx.cluster] = updatedSchedule
        indexingSchedule()
    }

//    func updateRevisitChangeInMasterSchedule(doneStation: String, revisitStation: String) {
//        var stationsInCluster = getUnvisitedStationsInCluster(doneStation: doneStation)
//        stationsInCluster.insert(revisitStation, at: 0)
//        let newSequence = self.stationRouting.getMinTimePermutationWithStart(startStat: revisitStation, statList: stationsInCluster)
//        let newRevisitClusterSchedule = getRevisitClusterSchedule(from: newSequence)
//
//        //print("[DR] stationsInCluster = \(stationsInCluster)")
//        print("[DR] newSequence = \(newSequence)")
//        print("[DR] newRevisitSchedule = \(newRevisitClusterSchedule)")
//
//        // Update remain schedule
//        remainSchedule = removeFirstCluster(schedule: remainSchedule)
//        remainSchedule = insertFirstCluster(clusterSchedule: newRevisitClusterSchedule, schedule: remainSchedule)
//
//        // Update master schedule
//        var newMasterSchedule: [[[VisitLog]]] = []
//        var newDaySchedule: [[VisitLog]] = []
//        let compareCluster = getNextCluster()
//        var preCluster: [VisitLog] = []
//        var found = false
//        for daySchedule in masterSchedule {
//            newDaySchedule = []
//            for clusterSchedule in daySchedule {
//                if isSameCluster(cluster1: clusterSchedule, cluster2: compareCluster) {
//                    found = true
//                    // Remove pre cluster from tmporary storage
//                    if newDaySchedule.count > 0 {
//                        newDaySchedule = Array(newDaySchedule[0..<newDaySchedule.count-1])
//                    } else {
//                        var lastDaySchedule = newMasterSchedule[newMasterSchedule.count-1]
//                        newMasterSchedule.removeLast()
//                        if lastDaySchedule.count != 1 {
//                            lastDaySchedule.removeLast()
//                            newMasterSchedule.append(lastDaySchedule)
//                        }
//                    }
//                    // Assemble current cluster
//                    for (i,visitLog) in preCluster.enumerated() {
//                        if visitLog.station == doneStation {
//                            newDaySchedule.append(Array(preCluster[0...i]))
//                            break
//                        }
//                    }
//                    newDaySchedule.append(newRevisitClusterSchedule)
//
//                }
//                newDaySchedule.append(clusterSchedule)
//                preCluster = clusterSchedule
//            }
//            newMasterSchedule.append(newDaySchedule)
//        }
//
//        // Revisit in last cluster
//        if !found {
//            newMasterSchedule.removeLast()
//            newDaySchedule.removeLast()
//            for (i,visitLog) in preCluster.enumerated() {
//                if visitLog.station == doneStation {
//                    newDaySchedule.append(Array(preCluster[0...i]))
//                    break
//                }
//            }
//            newDaySchedule.append(newRevisitClusterSchedule)
//            newMasterSchedule.append(newDaySchedule)
//        }
//        masterSchedule = newMasterSchedule
//        indexingSchedule()
//    }

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

    func applyInitialTimestamp(){
        for day in 0..<masterSchedule.count {
            applyTimestamp(day: day, startDate: self.beginDate)
        }
    }

    func applyTimestamp(day: Int, startDate: Date) {
        for cluster in 0..<masterSchedule[day].count {
            for log in 0..<masterSchedule[day][cluster].count {
                masterSchedule[day][cluster][log].date = startDate + masterSchedule[day][cluster][log].timestamp.seconds
            }
        }
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

    func getNextVisitLog() -> StatIndex {
        for day in 0..<masterSchedule.count {
            for cluster in 0..<masterSchedule[day].count {
                for i in 0..<masterSchedule[day][cluster].count {
                    let log = masterSchedule[day][cluster][i]
                    if !log.didVisit && !log.isSkip {
                        nextIdx = (day, cluster, i)
                        return nextIdx
                    }
//                    let station = masterSchedule[day][cluster][i].station
//                    let index = getStationIndex(station: station)
//                    if !stationsList[index].isVisited {
//                        return (day, cluster, i)
//                    }
                }
            }
        }
        return (-1, -1, -1)
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

//    func removeFirstStation() {
//        if remainSchedule.isEmpty {
//            print("[DR] remain Schedule is Empty")
//            return
//        }
//        // Remove first station
//        print("[DR] removePreStation")
//        //VisitLog.dumpMasterSchedule(schedule: remainSchedule)
//
//        let daySchedule = remainSchedule[0]
//        let clusterSchedule = daySchedule[0]
//
//        var newRemainSchedule: [[[VisitLog]]] = []
//        var newDaySchedule: [[VisitLog]] = []
//        var newClusterSchedule: [VisitLog] = []
//
//        if clusterSchedule.count >= 2 {
//            newClusterSchedule = Array(clusterSchedule[1..<clusterSchedule.count])
//        }
//
//        if !newClusterSchedule.isEmpty {
//            newDaySchedule.append(newClusterSchedule)
//        }
//        for (i, cluster) in daySchedule.enumerated() {
//            if i > 0 {
//                newDaySchedule.append(cluster)
//            }
//        }
//
//        if !newDaySchedule.isEmpty {
//            newRemainSchedule.append(newDaySchedule)
//        }
//        for (i, day) in remainSchedule.enumerated() {
//            if i > 0 {
//                newRemainSchedule.append(day)
//            }
//        }
//        remainSchedule = newRemainSchedule
//        //VisitLog.dumpMasterSchedule(schedule: remainSchedule)
//    }

    func handleSkipNextStation() {
        print("[DR] Skip \(nextVisitLog.station)")
        doneLoading = false
        DispatchQueue.global(qos: .userInitiated).async {
            sleep(LoadingView.delay)
            self.nextVisitLog.isSkip = true
            self.nextVisitLog.date = getCurrentDate()
            self.currentVisitPath.append(self.nextVisitLog)
            let index = self.getStationIndex(station: self.nextStation)
            self.stationsList[index].isScheduled = false

            self.setNextVisitLog(isRevisit: false)
            DispatchQueue.main.async {
                self.doneLoading = true
            }
        }
    }

    func isStationScheduled(station: String) -> Bool{
        let index = getStationIndex(station: station)
        return stationsList[index].isScheduled
    }

    func handleEndSurvey() {
        doneLoading = false
        DispatchQueue.global(qos: .userInitiated).async {
            sleep(LoadingView.delay)
            self.setNextVisitLog(isRevisit: false)
            DispatchQueue.main.async {
                self.doneLoading = true
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            print("[DR] Creating shcedule for tomorrow...")
            let clusters = self.createClusters()
            print("[DR] Done reclustering...")
            self.remainSchedule = self.clusterRouting.getCompleteSchedule(info: clusters, workingHour: 8, currentStat: BaseStation)

            let daySchedule = [self.currentVisitPath]
            self.masterSchedule = self.remainSchedule
            self.masterSchedule.insert(daySchedule, at: 0)
            self.indexingSchedule()
            //VisitLog.dumpMasterSchedule(schedule: self.remainSchedule)
            print("[DR] Done creating shcedule for tomorrow")
        }
    }
}
