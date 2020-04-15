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
    static let N: Int = 2 // hours
    var preStation: String = BaseStation
    var nextStation: String = "NASA"
    var nextTravelTime: String = "00:00"

    var isStarted = false
    let dayLimit: Int = 8 // hours
    let defaultTime: Date
    var beginTime: Date
    var lastRepeatTime: Date

    // Stations list page
    @Published var stationsList: [Station]
    var stationListBackUp: [Bool] = []

    //var day: Int = 0
    //var preStat: String


    var masterSchedule: [[VisitLog]] = [[]]
    var clusterRouting: ClusterRouting
    var stationRouting: StationRouting

    //var beginTime

    init(){
        //statSequence = stations_everyday[Day] ?? []
        stationsList = getStationsList()
        clusterRouting = ClusterRouting(clusterInfo: clusterInfo!, workingTime: dayLimit)
        stationRouting = StationRouting()

        defaultTime = getTimeFromStr(time: "2000-01-01 01:01:01+00000")
        beginTime = getTimeFromStr(time: "2020-01-01 09:00:00+00000")
        lastRepeatTime = beginTime
        //stationRouting.getMinTimePermutation(statList: clusterInfo!["1"]["stations"].arrayValue.map {$0.stringValue})
    }



    func makeRoutingSchedule(clusters: JSON, workintHour: Int, currentStat: String){
        masterSchedule = clusterRouting.getCompleteSchedule(info: clusters, workingHour: workintHour, currentStat: currentStat)
        updateFirstStation()
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

    func getNextStation(){
        print("getNextStation")

//        if preStat != PreStat{
//            print("Wrong pre stat \(preStat) and \(PreStat)")
//        }
//        if beginDate == nil{
//            beginDate = Date()
//            print("Begin date: \(beginDate!)")
//        }
//        let currentDate = Date()
//        if let beginDate = beginDate {
//            let elapsedTime: Int = (currentDate - (beginDate)).hour ?? -1
//            if  elapsedTime >= DynamicRouting.N{
//
//            }
//        }
//
//        return "USGS Office"
    }
}
