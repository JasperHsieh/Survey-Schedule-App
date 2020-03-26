//
//  ClusterRouting.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/23/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import SwiftyJSON

class ClusterRouting{
    var clusterInfo: JSON
    var workingTime: Int

    init(clusterInfo: JSON, workingTime: Int){
        self.clusterInfo = clusterInfo
        self.workingTime = workingTime
    }

    func getNextDaySchedule(info clusterInfo: JSON, workingTime: Int) -> Dictionary<Int, Any>{
        let statInfo = DataUtil.statInfo
        var clusterInfo = DataUtil.clusterInfo!

        clusterInfo = resetVisitedStatus(jsonObj: clusterInfo)

        var preStat = "CS25"

        while !visitedAll(jsonObj: clusterInfo){

            // choose the closest cluster
            var nextCluster = -1
            var minTime = -1
            for (cluster, _) in clusterInfo {
                if !clusterInfo[cluster]["visited"].bool! {
                    //let travelTime = getStatsTravelTime(preStat, clusterInfo[cluster]["start"])
                }
            }

        }
        return Dictionary()
    }

    func visitedAll(jsonObj: JSON) -> Bool{
        for (k, _) in jsonObj{
            //var tmp = jsonObj[k]["visited"]
            //print(tmp)
            if jsonObj[k]["visited"] == false {
                print("\(k) hasn't visited")
                return false
            }
        }
        print("All clusters has been visited")
        return true
    }

    func resetVisitedStatus(jsonObj: JSON) -> JSON{
        var jsonObjVisit: JSON = jsonObj
        for (k, _) in jsonObj{
            jsonObjVisit[k]["visited"] = false
        }
        //print(jsonObjVisit)
        return jsonObjVisit
    }
}
