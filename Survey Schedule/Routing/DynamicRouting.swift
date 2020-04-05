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

    static let baseStat: String = "CS25"
    static let N: Int = 2 // hours

    var isStarted = false
    let dayLimit: Int = 8 // hours
    var startTime = "10:00:00".toDate()
    @Published var stationsList: [Station]

    var day: Int = 0
    var preStat: String
    var beginDate: Date?

    var schedule: [Int: [VisitLog]] = [:]
    //var clusterInfo: JSON = DataUtil.clusterInfo ?? JSON()
    var clusterRouting: ClusterRouting

    //var beginTime

    init(Day: Int, PreStat: String){
        day = Day
        preStat = PreStat
        //statSequence = stations_everyday[Day] ?? []
        stationsList = getStationsList()
        clusterRouting = ClusterRouting(clusterInfo: clusterInfo!, workingTime: dayLimit)
    }

    func getSchedule(){
        schedule = clusterRouting.getNextDaySchedule(info: clusterInfo!, workingTime: dayLimit)
    }
//    func getNextStation(PreStat: String) -> String{
//        print("getNextStation")
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
//    }
}
