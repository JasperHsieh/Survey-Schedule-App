//
//  Station.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 4/1/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import CoreLocation

struct Station: Identifiable {
    var id: String
    var name: String
    //fileprivate var imageName: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

}



struct Coordinates: Hashable, Codable {
    var latitude: Double
    var longitude: Double
}
