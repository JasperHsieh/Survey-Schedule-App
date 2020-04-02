//
//  DataUtil.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/21/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import SwiftyJSON

let clusterInfoFile = "cluster_info"
let statInfoFile = "stat_info"
let statTravelTimeFile = "stat_travel_time"

let clusterInfo = readJsonFromFile(filePath: clusterInfoFile)
let statInfo = readJsonFromFile(filePath: statInfoFile)
let statTravelTimeInfo = readJsonFromFile(filePath: statTravelTimeFile)

var stationsList = getStationsList()

func readJsonFromFile(filePath: String) -> JSON?{
    //var jsonObj:JSON? = nil
    if let path = Bundle.main.path(forResource: filePath, ofType: "json") {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            let jsonObj = try JSON(data: data)
            //print("jsonData:\(jsonObj)")
            //print("jsonObj: \(jsonObj["B-14"]["J4"])")
            return jsonObj
        } catch let error {
            print("parse error: \(error.localizedDescription)")
        }
    } else {
        print("Invalid filename \(filePath)")
        return nil
    }
    //return jsonObj
    return nil
}

func getStatsTravelTime(stat1: String, stat2: String) -> Int {
    //print("getStatsTravelTime \(stat1) and \(stat2)")
    if stat1 == stat2 {
        return 0
    }
    if statTravelTimeInfo![stat1].exists() {
        //if let time = DataUtil.statTravelTimeInfo?[stat1][stat2].int {
        if statTravelTimeInfo![stat1][stat2].exists() {
            //let time = statTravelTimeInfo![stat1][stat2].intValue
            //print("getStatsTravelTime \(stat1) and \(stat2) \(time)")
            return statTravelTimeInfo![stat1][stat2].intValue
        }else {
            print("stat2 \(stat2) not found in \(stat1)")
        }
    }else{
        print("stat1 \(stat1) not found in statTravelTimeInfo")
    }
    return Int.max
}

func getStationsList()-> [Station] {
    //print(statInfo)
    var statList: [Station] = []
    for (station, _) in statInfo! {
        let id = statInfo![station]["id"].stringValue
        //let cluster = statInfo![station]["cluster"]
        statList.append(Station(id: id, name: station))
    }
    statList.sort {
        $0.name < $1.name
    }
    //print(statList)
    return statList
}

//struct DataUtil{
//    static let clusterInfoFile = "cluster_info"
//    static let statInfoFile = "stat_travel_time"
//    static let statTravelTimeFile = "stat_travel_time"
//
//    static let clusterInfo = readJsonFromFile(filePath: clusterInfoFile)
//    static let statInfo = readJsonFromFile(filePath: statInfoFile)
//    static let statTravelTimeInfo = readJsonFromFile(filePath: statTravelTimeFile)
//
//    static func readJsonFromFile(filePath: String) -> JSON?{
//        //var jsonObj:JSON? = nil
//        if let path = Bundle.main.path(forResource: filePath, ofType: "json") {
//            do {
//                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
//                let jsonObj = try JSON(data: data)
//                //print("jsonData:\(jsonObj)")
//                //print("jsonObj: \(jsonObj["B-14"]["J4"])")
//                return jsonObj
//            } catch let error {
//                print("parse error: \(error.localizedDescription)")
//            }
//        } else {
//            print("Invalid filename \(filePath)")
//            return nil
//        }
//        //return jsonObj
//        return nil
//    }
//
//    func getStatsTravelTime(stat1: String, stat2: String) -> Int {
//        //print("getStatsTravelTime \(stat1) and \(stat2)")
//        if stat1 == stat2 {
//            return 0
//        }
//        if DataUtil.statTravelTimeInfo![stat1].exists() {
//            //if let time = DataUtil.statTravelTimeInfo?[stat1][stat2].int {
//            if DataUtil.statTravelTimeInfo![stat1][stat2].exists() {
//                let time = DataUtil.statTravelTimeInfo![stat1][stat2].intValue
//                //print("getStatsTravelTime \(stat1) and \(stat2) \(time)")
//                return DataUtil.statTravelTimeInfo![stat1][stat2].intValue
//            }else {
//                print("stat2 \(stat2) not found in \(stat1)")
//            }
//        }else{
//            print("stat1 \(stat1) not found in statTravelTimeInfo")
//        }
//        return Int.max
//    }
//
//}
