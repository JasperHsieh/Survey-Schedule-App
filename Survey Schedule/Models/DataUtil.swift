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

let clusterInfo = readJsonFromFile(filePath: clusterInfoFile)
let statInfo = readJsonFromFile(filePath: statInfoFile)
let statTravelTimeInfo = readJsonFromFile(filePath: statTravelTimeFile)

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
        let coordinate = CLLocationCoordinate2D(latitude: 37.410686, longitude: -122.059141)
        //let cluster = statInfo![station]["cluster"]
        statList.append(Station(id: id, name: station, image: image, coordinate: coordinate))
    }
    statList.sort {
        $0.name < $1.name
    }
    //print(statList)
    return statList
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
