//
//  travelTime.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/21/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import SwiftyJSON

struct travelTime{
    //let path = "/Users/jasperhsieh/Documents/Courses/Practicum/Survey Schedule/Survey Schedule/resources/travelTime.json"
    //let travelTimeFile = "travelTime"
    let testFile = "test"
    static func readJsonFromFile(filePath: String){
        //let testFile = "test"
        let travelTimeFile = "travelTime"
        if let path = Bundle.main.path(forResource: travelTimeFile, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                let jsonObj = try JSON(data: data)
                //print("jsonData:\(jsonObj)")
                print("jsonObj: \(jsonObj["B-14"]["J4"])")
            } catch let error {
                print("parse error: \(error.localizedDescription)")
            }
        } else {
            print("Invalid filename \(filePath)")
        }
        /*let travelTimeFile = "travelTime"
        let testFile = "test"
        var jsonResult: Any?
        if let path = Bundle.main.path(forResource: testFile, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                print("data: \(data)")
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject>, let person = jsonResult["person"] as? [Any]{
                        // do stuff
                }
            } catch {
               // handle error
            }
        }else{
            print("File \(testFile) not found")
        }
        print("jsonResult: \(jsonResult)")
        return jsonResult*/
    }
}
