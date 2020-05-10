//
//  DataUtil.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/21/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftUI
import CoreLocation

/// The file name of original clustering
let clusterInfoFile = "cluster_info"

/// The file name of information of all stations
let statInfoFile = "stat_info"

/// The file name of Staitons travel time
let statTravelTimeFile = "stat_travel_time"

/// The file name of minimum time permutation of stations
let statPermCacheFile = "stat_perm_cache"

/// The file name of minimum time permutation of stations with particualr start station
let statPermStartCacheFile = "stat_perm_start_cache"

//let statDistFile = "stat_dist"

/// The clusters of stations in JSON
let clusterInfo = readJsonFromFile(filePath: clusterInfoFile)

/// The information of all stations in JSON
let statInfo = readJsonFromFile(filePath: statInfoFile)

/// The travel time between any two stations in JSON
let statTravelTimeInfo = readJsonFromFile(filePath: statTravelTimeFile)

/// The cache of minimum time permutation of stations
var statPermCache = readJsonFromFile(filePath: statPermCacheFile)

/// The cache of minimum time permutation of stations wiht particular start station
var statPermStartCache = readJsonFromFile(filePath: statPermStartCacheFile)
//let statDist = readJsonFromFile(filePath: statDistFile)

/// The repeat interval
let N = 2 * 60 * 60

/// Travel time threshhold
let M = 15 * 60

/// The working hour per day
let WorkingHour = 8

/// The reference station that should start with and end with
let BaseStation = "CS25"

/// Invalid station
let InvalidStation = "Mars"

/// The index of the visit log on master schedule
typealias StatIndex = (day: Int, cluster: Int, station: Int)

/**
Read the JSON from file
- Parameters:
    - filePath: The file name
- Returns: A JSON object
*/
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

/**
Get the travel time between two stations
- Parameters:
    - stat1: Start station
    - stat2: End station
- Returns: Travel time in second
*/
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

/**
Get the list for all stations
- Returns: An array of stations
*/
func getStationsList()-> [Station] {
    //print(statInfo)
    let images = ["turtlerock", "silversalmoncreek", "chilkoottrail", "stmarylake", "twinlake", "lakemcdonald", "yukon_charleyrivers", "icybay", "rainbowlake", "hiddenlake", "chincoteague", "umbagog"]
    var statList: [Station] = []
    for (station, _) in statInfo! {
        let id = statInfo![station]["id"].stringValue
        let image = "turtlerock"
        let coordinate = CLLocationCoordinate2D(latitude: statInfo![station]["coordinates"][0].doubleValue, longitude: statInfo![station]["coordinates"][1].doubleValue)
        //let coordinate = CLLocationCoordinate2D(latitude: 37.410686, longitude: -122.059141)
        //let cluster = statInfo![station]["cluster"]
        statList.append(Station(id: id, name: station, image: image, coordinate: coordinate))
    }
    statList.sort {
        $0.name < $1.name
    }

    for i in 0..<statList.count {
        statList[i].imageName = images[i % images.count]
    }
    //print(statList)
    return statList
}

/**
Get the start station of  the minumum time permutation station list
- Parameters:
    - stations: An array of station name
- Returns: The start station name
*/
func getStartStationFromCache(stations: [String]) -> String {
    let key = getKey(stations: stations)
    if statPermCache![key].exists() && statPermCache![key]["start"].exists(){
        return statPermCache![key]["start"].stringValue
    } else {
        return InvalidStation
    }
}

/**
Get the minimum time permutation of station list from cache
- Parameters:
    - stations: An array of station name
- Returns: The minimum time permutation
*/
func getMinPermStationFromCache(stations: [String]) -> [String] {
    let key = getKey(stations: stations)
    if statPermCache![key].exists() && statPermCache![key]["min_permutation"].exists(){
        return statPermCache![key]["min_permutation"].arrayValue.map {$0.stringValue}
    } else {
        return []
    }
}

/**
Get the minimum time permutation that start with the first station of station list
- Parameters:
    - stations: An array of station name
- Returns: The minimum time permutation start with first station of station list
*/
func getMinPermWithStartStationFromCache(stations: [String]) -> [String] {
    let start = stations[0]
    var key = getKey(stations: Array(stations[1..<stations.count]))
    key = start + "#" + key
    if statPermStartCache![key].exists() && statPermStartCache![key]["min_permutation"].exists() {
        return statPermStartCache![key]["min_permutation"].arrayValue.map {$0.stringValue}
    } else {
        return []
    }
}

/**
Save the minimum time permutation to cache
- Parameters:
    - minPerm: The minimum travel time permutation
*/
func setMinPermToCache(minPerm: [String]) {
    if minPerm.isEmpty {
        print("minStations is empty")
        return
    }
    let start = minPerm[0]
    var stats = minPerm
    stats.sort {$0 < $1}
    let key = getKey(stations: stats)
    if statPermCache![key].exists() {
        print("Key already exists in statPermCache")
    }
    //print("Set min permutation to cache \(key)")
    statPermCache![key] = JSON()
    statPermCache![key]["start"] = JSON(start)
    statPermCache![key]["min_permutation"] = JSON(minPerm)
}

/**
Get the key of the cache from station list
- Parameters:
    - stations: An array of station name
- Returns: The key for the cache
*/
func getKey(stations: [String]) -> String {
    var stats = stations
    stats.sort {$0 < $1}
    var key = ""
    for stat in stats {
        key = key + stat + "#"
    }
    return key
}

final class ImageStore {
    typealias _ImageDictionary = [String: CGImage]
    fileprivate var images: _ImageDictionary = [:]

    fileprivate static var scale = 2

    static var shared = ImageStore()

    func image(name: String) -> Image {
        let index = _guaranteeImage(name: name)

        return Image(images.values[index], scale: CGFloat(ImageStore.scale), label: Text(name))
    }

    static func loadImage(name: String) -> CGImage {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
            let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
            let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            fatalError("Couldn't load image \(name).jpg from main bundle.")
        }
        return image
    }

    fileprivate func _guaranteeImage(name: String) -> _ImageDictionary.Index {
        if let index = images.index(forKey: name) { return index }

        images[name] = ImageStore.loadImage(name: name)
        return images.index(forKey: name)!
    }
}
