//
//  Station.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 4/1/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit

/**
 Represent the station that needs to be measured. **Station** contain all the station information including the
 coordinates, name, image,  scheduling and visited or not.
 */
class Station: NSObject, Identifiable, MKAnnotation {
    /// The coordinates of the station in (latitude, longitude)
    var coordinate: CLLocationCoordinate2D

    /// Unique id of the station
    var id: String

    /// Name of the station
    var name: String

    /// Whether the station Is scheduled on the master schedule
    var isScheduled = true

    /// Whether the station is visited or not
    var isVisited = false

    /// The image name of the station in station details
    var imageName: String

    /**
     Initialize a new station
        - Parameters:
            - id: A unique id of the station
            - name: The name of the station
            - image: The name of the station image
            - coordinate: The location of the station
     */
    init(id: String, name: String, image: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.imageName = image
        self.coordinate = coordinate
    }

}

extension Station {
    var image: Image {
        ImageStore.shared.image(name: imageName)
    }
}

struct Coordinates: Hashable, Codable {
    var latitude: Double
    var longitude: Double
}
