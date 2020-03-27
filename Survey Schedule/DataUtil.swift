//
//  DataUtil.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/21/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import SwiftyJSON

struct DataUtil{
    static let clusterInfoFile = "cluster_info"
    static let statInfoFile = "stat_travel_time"
    static let statTravelTimeFile = "stat_travel_time"

    static let clusterInfo = readJsonFromFile(filePath: clusterInfoFile)
    static let statInfo = readJsonFromFile(filePath: statInfoFile)
    static let statTravelTime = readJsonFromFile(filePath: statTravelTimeFile)

    static func readJsonFromFile(filePath: String) -> JSON?{
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
        print("getStatsTravelTime \(stat1) and \(stat2)")
        if DataUtil.statTravelTime?[stat1].string == nil || DataUtil.statTravelTime?[stat2].string == nil {
            print("\(stat1) or \(stat2) not found in travel time file")
            return Int.max
        }
        if let time = DataUtil.statTravelTime?[stat1][stat2].int {
            return time
        } else{
            print("Coundn't find \(stat2) from \(stat1) item")
            return Int.max
        }
    }

}
