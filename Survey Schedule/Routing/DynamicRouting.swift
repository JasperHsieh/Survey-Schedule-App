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

    var preVisitLog: VisitLog
    var nextVisitLog: VisitLog
    var nextIdx: StatIndex
    @Published var nextStation: String = "NASA"
    @Published var nextTravelTime: String = "00:00"
    @Published var doneLoading: Bool = true

    var isStarted = false
    let dayLimit: Int = 8 // hours
    let defaultTime: Date
    var beginDate: Date
    var lastRepeatTime: Int
    var today: Int
    var doneToday: Bool

    // Stations list page
    @Published var stationsList: [Station]
    var stationListBackUp: [Bool] = []

    var masterSchedule: [[[VisitLog]]] = []
    var clusterRouting: ClusterRouting
    var stationRouting: StationRouting

    var currentVisitPath: [VisitLog] = []

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
        doneToday = false
        //stationRouting.getMinTimePermutation(statList: clusterInfo!["1"]["stations"].arrayValue.map {$0.stringValue})
    }

    func reset() {
        print("[DR] reset")
        beginDate = getCurrentDate()
        lastRepeatTime = 0
        preVisitLog.date = beginDate
        setStartDate(day: today, startDate: beginDate)
        applyTimeInterval(day: today)
        VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
    }

    func makeInitialSchedule() {
        DispatchQueue.global(qos: .userInitiated).async {
            //print("This is run on the background queue")
            //self.makeRoutingSchedule(clusters: clusterInfo ?? JSON(), workintHour: WorkingHour, currentStat: BaseStation)
            self.masterSchedule = self.clusterRouting.getCompleteSchedule(info: clusterInfo ?? JSON(), workingHour: WorkingHour, currentStat: BaseStation)
            let dummyDay = false
            if dummyDay {
                let tmpDay = [VisitLog(stat: BaseStation, timestamp: -1, isRevisit: false), VisitLog(stat: "CSE1", timestamp: -1, isRevisit: false), VisitLog(stat: "RE4", timestamp: -1, isRevisit: false)]
                self.masterSchedule.insert([tmpDay], at: 0)
            }
            self.indexingSchedule()
            self.applyInitialTimestamp()

            VisitLog.dumpDaySchedule(daySchedule: self.masterSchedule[0])
            DispatchQueue.main.async {
                self.setNextVisitLog(isRevisit: false)
                self.setNextStation()
                //self.updateNextStation()
                //self.removeFirstStation()
            }
        }
    }

    func mergeSchedule(updatedSchedule: [[[VisitLog]]]) {
        var updatedSchedule = updatedSchedule
        updatedSchedule[0].insert(currentVisitPath, at: 0)
        masterSchedule = updatedSchedule
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
        //print("[DR] setNextVisitLog")
        let statIdx = self.getNextVisitLog()
        if statIdx.day != today {
            print("No more stations today")
            setBaseStation()
            doneToday = true
            return
        }
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

    func getNextVisitLog() -> StatIndex {
        for day in 0..<masterSchedule.count {
            for cluster in 0..<masterSchedule[day].count {
                for i in 0..<masterSchedule[day][cluster].count {
                    let log = masterSchedule[day][cluster][i]
                    if !log.didVisit && !log.isSkip {
                        nextIdx = (day, cluster, i)
                        return nextIdx
                    }
                }
            }
        }
        return (-1, -1, -1)
    }

    func isStationScheduled(station: String) -> Bool{
        let index = getStationIndex(station: station)
        return stationsList[index].isScheduled
    }
}

// Done visiting station
extension DynamicRouting {

    func doneVisitStation() {
        doneLoading = false
        DispatchQueue.global(qos: .userInitiated).async {
            sleep(LoadingView.delay)
            self.HandleDoneAction()
            DispatchQueue.main.async {
                self.setNextStation()
                self.doneLoading = true
                if self.doneToday {
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.updateScheduleTomorrow()
                    }
                }
            }
        }
    }

    func HandleDoneAction(){
        print("[DR] HandleDoneAction \(nextVisitLog.station)")
        // Save preStation visit log
        let simulateRevisit = false
        var currentDate = getCurrentDate()

        preVisitLog = nextVisitLog
        if simulateRevisit && preVisitLog.station == "RE4" {
            currentDate = currentDate + 3.hours
        }
        let timeSoFar = getDiffInSec(start: beginDate, end: currentDate)
        print("[DR] currentDate \(currentDate)")
        setPreStationVisited()
        if preVisitLog.isRevisit {
            lastRepeatTime = timeSoFar
        }
        preVisitLog.didVisit = true

        let timeOffset = (currentDate - preVisitLog.date)
        //print("[DR] offset \(timeOffset) \(currentDate) \(preVisitLog.date)")
        preVisitLog.date = currentDate

        currentVisitPath.append(preVisitLog)

        if doneToday {
            doneToday = false
            setNextVisitLog(isRevisit: false)
            VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
            //VisitLog.dumpDaySchedule(daySchedule: masterSchedule[1])
            return
        }

        if timeSoFar - lastRepeatTime > N {
            print("[DR] Time to revisit")
            if currentVisitPath.isEmpty {
                print("[DR] No visited stations")
            } else {
                var minTravelTime = Int.max
                var minVisitLog: VisitLog?

                for visitLog in currentVisitPath {
                    if !visitLog.didVisit || visitLog.station == preVisitLog.station {
                        continue
                    }
                    let curTravelTime = getStatsTravelTime(stat1: preVisitLog.station, stat2: visitLog.station)
                    //print("[DR] \(preVisitLog.station)<->\(visitLog.station) \(curTravelTime)")
                    //let tmp  = timeSoFar + curTravelTime - visitLog.timestamp
                    //print("[DR] tmp \(tmp)")

                    //let time1 = timeSoFar + curTravelTime - visitLog.timestamp
                    //print("[DR] \(visitLog.station) \(curTravelTime) \(time1)")
                    //print("[DR] \(visitLog.station) time1=\(time1) timeSoFar=\(timeSoFar) curTravelTime=\(curTravelTime) timestamp=\(visitLog.timestamp) ")
                    if  curTravelTime < M && (timeSoFar + curTravelTime - visitLog.timestamp > N) && curTravelTime < minTravelTime {
                        minTravelTime = curTravelTime
                        minVisitLog = visitLog
                    }
                }
                if let minVisitLog = minVisitLog {
                    print("[DR] Revisit \(minVisitLog.station)")
                    //updateRevisitChange(doneStation: preVisitLog.station, revisitStation: minVisitLog.station)
                    let clusters = self.createClusters()
                    print(clusters)

                    let updatedSchedule = self.clusterRouting.getCompleteSchedule(info: clusters, workingHour: 8, currentStat: minVisitLog.station)
                    mergeSchedule(updatedSchedule: updatedSchedule)

                    indexingSchedule()
                    setNextVisitLog(isRevisit: true)
                    setStartDate(day: today, startDate: beginDate)
                    updateTimestamp(offset: timeOffset)
                    applyTimeInterval(day: today)
                    for day in today+1..<masterSchedule.count {
                            applyTimeInterval(day: day)
                    }
                } else {
                    print("[DR] No valid revisit station. T_T")
                }
            }
        } else {
            //print("[DR] Go to next station")
            //removeFirstStation()
            setNextVisitLog(isRevisit: false)
            updateTimestamp(offset: timeOffset)
        }
        VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
        //VisitLog.dumpDaySchedule(daySchedule: masterSchedule[1])
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

}

// Apply station changes
extension DynamicRouting {

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

            self.setStartDate(day: self.today, startDate: self.beginDate)
            self.applyTimeInterval(day: self.today)
            for day in self.today+1..<self.masterSchedule.count {
                self.applyTimeInterval(day: day)
            }
            print("[DR] After applying")
            VisitLog.dumpDaySchedule(daySchedule: self.masterSchedule[0])
            //sleep(LoadingView.delay)
            DispatchQueue.main.async {
                self.setNextStation()
                self.doneLoading = true
            }
        }
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
}

// Troubleshooting
extension DynamicRouting {

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
                self.setNextStation()
                self.doneLoading = true
            }
        }
    }

    func handleEndSurvey() {
        doneLoading = false
        DispatchQueue.global(qos: .userInitiated).async {
            sleep(LoadingView.delay)
            self.setBaseStation()
            DispatchQueue.main.async {
                self.doneLoading = true
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.updateScheduleTomorrow()
        }
    }

    func setBaseStation() {
        nextVisitLog = VisitLog(stat: BaseStation, timestamp: -1, isRevisit: false)
        setNextStation()
    }

    func updateScheduleTomorrow() {
        print("[DR] Creating shcedule for tomorrow...")
        let clusters = createClusters()
        print("[DR] Done reclustering...")
        let tmrSchedule = clusterRouting.getCompleteSchedule(info: clusters, workingHour: 8, currentStat: BaseStation)

        var daySchedule = [currentVisitPath]
        daySchedule.append([VisitLog(stat: BaseStation, timestamp: -1, isRevisit: false)])

        masterSchedule = tmrSchedule
        masterSchedule.insert(daySchedule, at: 0)
        indexingSchedule()
        for day in today+1..<masterSchedule.count {
            applyTimeInterval(day: day)
        }
        setNextVisitLog(isRevisit: false)
        let travelTime = getStatsTravelTime(stat1: preVisitLog.station, stat2: BaseStation)
        nextVisitLog.date = getCurrentDate() + travelTime.seconds

        doneToday = true
        today += 1
        print("[DR] Done creating shcedule for tomorrow")
    }
}

// Timestamp changes
extension DynamicRouting {

    func applyInitialTimestamp(){
        for day in 0..<masterSchedule.count {
            setStartDate(day: day, startDate: self.beginDate)
            applyTimeInterval(day: day)
        }
    }

    func applyTimeInterval(day: Int) {
        for cluster in 0..<masterSchedule[day].count {
            for log in 0..<masterSchedule[day][cluster].count {
                if cluster < nextIdx.cluster || (cluster == nextIdx.cluster && log < nextIdx.station) {
                    continue
                }
                masterSchedule[day][cluster][log].date = masterSchedule[day][cluster][log].date + masterSchedule[day][cluster][log].timestamp.seconds
            }
        }
    }

    func setStartDate(day: Int, startDate: Date) {
        for cluster in 0..<masterSchedule[day].count {
            for log in 0..<masterSchedule[day][cluster].count {
                if cluster < nextIdx.cluster || (cluster == nextIdx.cluster && log < nextIdx.station) {
                    continue
                }
                masterSchedule[day][cluster][log].date = startDate
            }
        }
    }

    func updateTimestamp(offset: DateComponents) {
        print("[DR] updateTimestamp \(preVisitLog.date)")
        //print("[DR] \(masterSchedule[nextIdx.day][nextIdx.cluster][nextIdx.station].station)")
        for cluster in 0..<masterSchedule[today].count {
            for log in 0..<masterSchedule[today][cluster].count {
                if today < nextIdx.day  || (today == nextIdx.day && cluster < nextIdx.cluster) || (today == nextIdx.day && cluster == nextIdx.cluster && log < nextIdx.station) {
                        continue
                    }
                    masterSchedule[today][cluster][log].date = offset + masterSchedule[today][cluster][log].date
            }
        }
    }
}
