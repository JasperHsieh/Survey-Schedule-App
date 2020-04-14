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

let clusterInfoFile = "cluster_info"
let statInfoFile = "stat_info"
let statTravelTimeFile = "stat_travel_time"
let statPermCacheFile = "stat_perm_cache"
let statPermStartCacheFile = "stat_perm_start_cache"

let clusterInfo = readJsonFromFile(filePath: clusterInfoFile)
let statInfo = readJsonFromFile(filePath: statInfoFile)
let statTravelTimeInfo = readJsonFromFile(filePath: statTravelTimeFile)
var statPermCache = readJsonFromFile(filePath: statPermCacheFile)
var statPermStartCache = readJsonFromFile(filePath: statPermStartCacheFile)

let WorkingHour = 8
let BaseStation = "CS25"
let InvalidStation = "Mars"

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
        let image = "chilkoottrail"
        let coordinate = CLLocationCoordinate2D(latitude: statInfo![station]["coordinates"][0].doubleValue, longitude: statInfo![station]["coordinates"][1].doubleValue)
        //let coordinate = CLLocationCoordinate2D(latitude: 37.410686, longitude: -122.059141)
        //let cluster = statInfo![station]["cluster"]
        statList.append(Station(id: id, name: station, image: image, coordinate: coordinate))
    }
    statList.sort {
        $0.name < $1.name
    }
    //print(statList)
    return statList
}

func getStartStationFromCache(stations: [String]) -> String {
    let key = getKey(stations: stations)
    if statPermCache![key].exists() && statPermCache![key]["start"].exists(){
        return statPermCache![key]["start"].stringValue
    } else {
        return InvalidStation
    }
}

func getMinPermStationFromCache(stations: [String]) -> [String] {
    let key = getKey(stations: stations)
    if statPermCache![key].exists() && statPermCache![key]["min_permutation"].exists(){
        return statPermCache![key]["min_permutation"].arrayValue.map {$0.stringValue}
    } else {
        return []
    }
}

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
    print("Set min permutation to cache \(key)")
    statPermCache![key] = JSON()
    statPermCache![key]["start"] = JSON(start)
    statPermCache![key]["min_permutation"] = JSON(minPerm)
}

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
