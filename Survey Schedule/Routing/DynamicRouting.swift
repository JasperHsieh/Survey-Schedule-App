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

/**
 Represent the dynamic routing handler. The class is reponsible for do the real-time calculation to
 update the UI station and schedule. The **DynamicRouting** will check the repeat time whenever a user
 tap Done button and generate the next station. **ClusterRouting** object is used to get the new schedule when
 it's time to revisit previous station, change of station scheduling and end the survey.

 When a user chagne the scheduling of stations, **DynamicRouting** will also use **ClusterRouting** object
 to calculate the full schedule with the changes and update to master. Same action will happen when a user tap End Survey today.

 - ToDo: currentVisitPath should be two dimensional array to represent the visit log for different days.

 - SeeAlso:
    - ClusterRouting
    - StationRouting

 */
class DynamicRouting: ObservableObject{
    /// Previous visit log
    var preVisitLog: VisitLog

    /// Next visit log
    var nextVisitLog: VisitLog

    /// The index of next visit log on master schedule
    var nextIdx: StatIndex

    /// The next station name that shows in Next Station section
    @Published var nextStation: String = "NASA"

    /// The travel time to next station that shows in Next Station section
    @Published var nextTravelTime: String = "00:00"

    /// The bool indecates whether shows the loading view or not
    @Published var doneLoading: Bool = true

    /// The working hour for a day in hours
    let dayLimit: Int = 8

    /// The default date in the app
    let defaultTime: Date

    /// The date a user done with the first station of a day
    var beginDate: Date

    /// The timestamp that last revisit happened
    var lastRepeatTime: Int

    /// The current day on master schedule
    var today: Int

    /// True, if done with last station, not CS25, on today's schedule
    var doneToday: Bool

    /// Station list
    @Published var stationsList: [Station]

    /// Copy of all stations scheduling
    var stationListBackUp: [Bool] = []

    /// The master schedule
    var masterSchedule: [[[VisitLog]]] = []

    /// The cluster routing object
    var clusterRouting: ClusterRouting

    /// The station routing object
    var stationRouting: StationRouting

    /// Current visit log so far.  TODO: Make currentVisitPath two dimensional array to indicate the visit log for different days
    var currentVisitPath: [VisitLog] = []

    /**
     Initializes a new dynamicRouting. The original clusters will be obtain from file and the default date will be set.
     */
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
    }
    /**
     Reset basic setting when a user done with first station which should be CS25
     */
    func reset() {
        print("[DR] reset")
        beginDate = getCurrentDate()
        lastRepeatTime = 0
        preVisitLog.date = beginDate
        setStartDate(day: today, startDate: beginDate)
        applyTimeInterval(day: today)
        VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
    }
    /**
    Create initial master schedule when first open the app.

    Todo: The initial master schedule should be from file
    */
    func makeInitialSchedule() {
        DispatchQueue.global(qos: .userInitiated).async {
            //print("This is run on the background queue")
            //self.makeRoutingSchedule(clusters: clusterInfo ?? JSON(), workintHour: WorkingHour, currentStat: BaseStation)
            self.masterSchedule = self.clusterRouting.getCompleteSchedule(info: clusterInfo ?? JSON(), workingHour: WorkingHour, currentStat: BaseStation)

            /// Create dummy day for debuggin
            let dummyDay = false
            if dummyDay {
                let tmpDay = [VisitLog(stat: BaseStation, timestamp: -1, isRevisit: false), VisitLog(stat: "CSE1", timestamp: -1, isRevisit: false), VisitLog(stat: "RE4", timestamp: -1, isRevisit: false)]
                self.masterSchedule.insert([tmpDay], at: 0)
            }

            self.indexingSchedule()
            self.applyInitialTimestamp()

            VisitLog.dumpDaySchedule(daySchedule: self.masterSchedule[0])
            DispatchQueue.main.async {
                self.getNextIdx()
                self.setNextVisitLog(isRevisit: false)
                self.setNextStation()
                //self.updateNextStation()
                //self.removeFirstStation()
            }
        }
    }
    /**
     Update the master schedule by append updatedSchedule to currentVisitPath
     - Parameters:
        - updatedSchedule: the updated schedule that need to be appened
     */
    func mergeSchedule(updatedSchedule: [[[VisitLog]]]) {
        var updatedSchedule = updatedSchedule
        updatedSchedule[0].insert(currentVisitPath, at: 0)
        masterSchedule = updatedSchedule
    }
    /**
    Remove the first visitlog from the schedule
    - Parameters:
       - schedule: the schedule that need to be removed first station
    - Returns: A schedule with first station removed
    */
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
    /**
    Get the next scheduled station which should be not be visited and not skpped
    */
    func getNextIdx(){
        //print("[DR] getNextIdx")
        for day in 0..<masterSchedule.count {
            for cluster in 0..<masterSchedule[day].count {
                for i in 0..<masterSchedule[day][cluster].count {
                    let log = masterSchedule[day][cluster][i]
                    if !log.didVisit && !log.isSkip {
                        nextIdx = (day, cluster, i)
                        return
                    }
                }
            }
        }
        print("[DR] Cannot find next visitlog")
        nextIdx = (-1, -1, -1)
    }
    /**
        Update the next visit log from nextIdx
     - Parameters:
            - isRevisit: Indicates the next visit log should be revisit or not
     */
    func setNextVisitLog(isRevisit: Bool) {
        if nextIdx == (-1, -1, -1) {
            print("Invalid nextIdx \(nextIdx)")
        }
        nextVisitLog = masterSchedule[nextIdx.day][nextIdx.cluster][nextIdx.station]
        nextVisitLog.isRevisit = isRevisit
    }
    /**
    Set the next station name in Next Station section
    */
    func setNextStation() {
        DispatchQueue.main.async {
            print("[DR] setNextStation \(self.nextVisitLog.station)")
            self.nextStation = self.nextVisitLog.station
            let timeToNextStation = getStatsTravelTime(stat1: self.preVisitLog.station, stat2: self.nextStation)
            self.nextTravelTime = getTravelTimeString(sec: timeToNextStation)
        }
    }
    /**
    Create clusters from those unvisited and scheduled stations.
    - Returns: The new clusters with JSON format
    */
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
            print("[DR] Creating cluster \(cluster) \(stations)")
            clustersJson[cluster] = JSON()
            clustersJson[cluster]["stations"] = JSON(stations)
            clustersJson[cluster]["start"] = JSON(stationRouting.getStartStat(statList: stations))
        }
        return clustersJson
    }
    /**
    Get the cluster that consis of the staion
    - Parameters:
       - station: the station
    - Returns: A cluster id
    */
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
    /**
    Set visited for the station that a user just done with measurement
    */
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
    /**
    Get the station index in stationsList
    - Parameters:
       - station: the station name string
    - Returns: An index for stationsList
    */
    func getStationIndex(station: String) -> Int {
        let index = stationsList.firstIndex(where: {$0.name == station}) ?? -1
        return index
    }
    /**
    Remove first cluster in the schedule
    - Parameters:
       - schedule: the schedule
    - Returns: An new schedule with first cluster removed
    */
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

    /**
    Insert a cluster in the front of the schedule
    - Parameters:
        - clusterSchedule: the array of visitlog
        - schedule: the schedule to inserted
    - Returns: An new schedule with the cluster inserted
    */
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

    /**
     Create a cluster which is an array of visitlog from list of station name
    - Parameters:
        - stations: An array of station name
    - Returns: An array of visitlog as a cluster
    */
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

    /**
     Create index for all visitlog in the master schedule in order to gray out the scheduled station
    */
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

    /**
     Check the station is schedule or not
    - Parameters:
        - station: A station name
    - Returns: true if scheduled
    */
    func isStationScheduled(station: String) -> Bool{
        let index = getStationIndex(station: station)
        return stationsList[index].isScheduled
    }
}

// Done visiting station
extension DynamicRouting {
    /**
     Check the next station is the first station of a day or not
    - Returns: true if is the first station
    */
    func isFirstStation() -> Bool {
        if nextIdx.cluster == 0 && nextIdx.station == 0 {
            return true
        }
        return false
    }
    /**
     Handle done with a station in the background
    */
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
    /**
     Handle done with the measurement of a station

     **Steps**
     1. Save next station to previous station
     2. Check if it is time to revisit a station
     3. Choose closest revisit station if exceed repeat time interval. Otherwise go to next station on master schedule
    */
    func HandleDoneAction(){
        print("[DR] HandleDoneAction \(nextVisitLog.station)")
        // Save preStation visit log
        let simulateRevisit = false
        var currentDate = getCurrentDate()
        preVisitLog = nextVisitLog

        /// Add fake time to simulate revisiting
        if simulateRevisit && masterSchedule[nextIdx.day][nextIdx.cluster][nextIdx.station].index >= 2 {
            currentDate = currentDate + 3.hours
        }

        /// Calculate the time offset from the the scheduled time
        print("[DR] currentDate \(currentDate)")
        let timeSoFar = getDiffInSec(start: beginDate, end: currentDate)
        let timeOffset = (currentDate - preVisitLog.date)
        //print("[DR] offset \(timeOffset) \(currentDate) \(preVisitLog.date)")

        /// Set previous station visited
        setPreStationVisited()
        if preVisitLog.isRevisit {
            lastRepeatTime = timeSoFar
        }
        preVisitLog.didVisit = true
        preVisitLog.date = currentDate
        currentVisitPath.append(preVisitLog)

        if doneToday {
            print("[DR] Done today")
            doneToday = false
            getNextIdx()
            setNextVisitLog(isRevisit: false)
            //VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
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
                    /// Consider non-skipped station only
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
                    let clusters = self.createClusters()
                    print(clusters)

                    let updatedSchedule = self.clusterRouting.getCompleteSchedule(info: clusters, workingHour: 8, currentStat: minVisitLog.station)
                    mergeSchedule(updatedSchedule: updatedSchedule)

                    /// index the master schedule when it changes
                    indexingSchedule()

                    /// Set the next visit log
                    getNextIdx()
                    setNextVisitLog(isRevisit: true)

                    /// Update timestamp on master schedule
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
            getNextIdx()
            if nextIdx.day != today {
                print("[DR] No more stations today")
                appendBaseStation()
                doneToday = true
                return
            }

            setNextVisitLog(isRevisit: false)
            updateTimestamp(offset: timeOffset)
        }
        //VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])
        //VisitLog.dumpDaySchedule(daySchedule: masterSchedule[1])
    }
    /**
     Check the station is schedule or not
    - Parameters:
        - station: A station name
    - Returns: true if scheduled
    */
//    func getUnvisitedStationsInCluster() -> [String]{
//        var stations:Set = Set<String>()
//        let cluster = masterSchedule[nextIdx.day][nextIdx.cluster]
//        for i in nextIdx.station+1..<cluster.count {
//            stations.insert(cluster[i].station)
//        }
//        return Array(stations)
//    }
//
//    func updateRevisitChange(doneStation: String, revisitStation: String) {
//        var stationsInCluster = getUnvisitedStationsInCluster()
//        stationsInCluster.insert(revisitStation, at: 0)
//        let newSequence = self.stationRouting.getMinTimePermutationWithStart(startStat: revisitStation, statList: stationsInCluster)
//        let newRevisitClusterSchedule = getRevisitClusterSchedule(from: newSequence)
//        print("[DR] stationsInCluster:\(stationsInCluster)")
//        print("[DR] newSequence:\(newSequence)")
//        var updatedSchedule = Array(masterSchedule[nextIdx.day][nextIdx.cluster][0...nextIdx.station])
//        updatedSchedule.append(contentsOf: newRevisitClusterSchedule)
//
//        masterSchedule[nextIdx.day][nextIdx.cluster] = updatedSchedule
//        indexingSchedule()
//    }
}

// Apply station changes
extension DynamicRouting {
    /**
     Handle the stations change

     **Steps**
     1. Re-clustering
     2. Get full schedule
     3. Update to the master schedule
    */
    func applyStationsChange() {
        print("[DR] Applying change..., preVisitLog: \(preVisitLog.station)")
        doneLoading = false
        DispatchQueue.global(qos: .userInitiated).async {
            let clusters = self.createClusters()
            print("[DR] Done reclustering...")
            //print(clusters)
            //VisitLog.dumpDaySchedule(daySchedule: self.masterSchedule[0])

            var updatedSchedule = self.clusterRouting.getCompleteSchedule(info: clusters, workingHour: 8, currentStat: self.preVisitLog.station)
            updatedSchedule = self.removeFirstStation(schedule: updatedSchedule)

            /// index the master schedule when it changes
            self.mergeSchedule(updatedSchedule: updatedSchedule)
            self.indexingSchedule()

            /// Set the next visit log
            self.getNextIdx()
            self.setNextVisitLog(isRevisit: false)

            /// Update timestamp on master schedule
            self.setStartDate(day: self.today, startDate: self.beginDate)
            self.applyTimeInterval(day: self.today)
            for day in self.today+1..<self.masterSchedule.count {
                self.applyTimeInterval(day: day)
            }
            print("[DR] Done applying change")
            VisitLog.dumpDaySchedule(daySchedule: self.masterSchedule[0])
            //sleep(LoadingView.delay)
            DispatchQueue.main.async {
                self.setNextStation()
                self.doneLoading = true
            }
        }
    }

    /**
     Create a backup station list to know what station change
    */
    func backupStationsSetting() {
        print("[DR] backupStationsSetting")
        stationListBackUp = []
        for station in stationsList {
            stationListBackUp.append(station.isScheduled)
        }
    }
    /**
     Check whether the stations has been changed
    - Returns: true if a station changed
    */
    func isScheduledStationsChanged() -> Bool {
        for (i, station) in stationsList.enumerated() {
            if station.isScheduled != stationListBackUp[i] {
                print("[DR] station \(station.name) changed")
                return true
            }
        }
        return false
    }
}

// Troubleshooting
extension DynamicRouting {
    /**
     Handle the action when Skip Station tapped.
    */
    func handleSkipNextStation() {
        print("[DR] Skip \(nextVisitLog.station)")
        doneLoading = false
        DispatchQueue.global(qos: .userInitiated).async {
            sleep(LoadingView.delay)
            /// Set visit log skipped
            self.nextVisitLog.isSkip = true
            self.nextVisitLog.date = getCurrentDate()
            self.currentVisitPath.append(self.nextVisitLog)

            /// Set the station to be not scheduled
            let index = self.getStationIndex(station: self.nextStation)
            self.stationsList[index].isScheduled = false

            /// Set the next visit log
            self.getNextIdx()
            self.setNextVisitLog(isRevisit: false)
            DispatchQueue.main.async {
                self.setNextStation()
                self.doneLoading = true
            }
        }
    }

    /**
     Handle the action when End Survey tapped
    */
    func handleEndSurvey() {
        doneLoading = false
        doneToday = true
        DispatchQueue.global(qos: .userInitiated).async {
            /// Update master schedule
            sleep(LoadingView.delay)
            self.appendBaseStation()
            DispatchQueue.main.async {
                self.doneLoading = true
            }
        }

        /// Calculate the schedule for tomorrow
        DispatchQueue.global(qos: .userInitiated).async {
            self.updateScheduleTomorrow()
        }
    }

    /**
     Append the base station to the end of visited station and update the master schedule
    */
    func appendBaseStation() {
        let tmpBase = VisitLog(stat: BaseStation, timestamp: -1, isRevisit: false)
        let travelTime = getStatsTravelTime(stat1: preVisitLog.station, stat2: BaseStation)
        tmpBase.date = getCurrentDate() + travelTime.seconds
        var daySchedule = [currentVisitPath]
        daySchedule.append([tmpBase])
        masterSchedule.remove(at: 0)
        masterSchedule.insert(daySchedule, at: 0)
        indexingSchedule()
        getNextIdx()
        setNextVisitLog(isRevisit: false)
        setNextStation()
    }

    /**
        Calculate the schedule for next day and update the master schdule when it's done
    */
    func updateScheduleTomorrow() {
        print("[DR] Creating shcedule for tomorrow...")
        let clusters = createClusters()
        print("[DR] Done reclustering...")
        var tmrSchedule = clusterRouting.getCompleteSchedule(info: clusters, workingHour: 8, currentStat: BaseStation)
        VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])

        /// Keep the schedule of previous days
        for day in 0...today {
            tmrSchedule.insert(masterSchedule[day], at: day)
        }
        masterSchedule = tmrSchedule

        /// index the master schedule when it changes
        indexingSchedule()
        for day in today+1..<masterSchedule.count {
            applyTimeInterval(day: day)
        }
        VisitLog.dumpDaySchedule(daySchedule: masterSchedule[0])

        /// Set the next visit log
        getNextIdx()
        setNextVisitLog(isRevisit: false)
        today += 1
        print("[DR] Done creating shcedule for tomorrow")
    }
}

// Timestamp changes
extension DynamicRouting {

    /**
     Set the begin time to all stations and apply the timestamp
    */
    func applyInitialTimestamp(){
        for day in 0..<masterSchedule.count {
            setStartDate(day: day, startDate: self.beginDate)
            applyTimeInterval(day: day)
        }
    }

    /**
     Append the base station to the end of visited station and update the master schedule
     - Parameters:
         - day: The day of schedule should be applied
    */
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

    /**
     Set start date for the rest of scheduled station of the day
     - Parameters:
         - day: The day of the master schedule that should be applied
         - startDate: The date want to be set
    */
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

    /**
     Update the ETA for the rest of schedule station today
     - Parameters:
         - offset: The time interval to be added
    */
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
