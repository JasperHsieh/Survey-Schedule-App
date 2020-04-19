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

class Station: NSObject, Identifiable, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String? = "Title"
    var id: String
    var name: String
    var isScheduled = true
    var isVisited = false
    fileprivate var imageName: String
    //var locationCoordinate: CLLocationCoordinate2D

    init(id: String, name: String, image: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.imageName = image
        self.coordinate = coordinate
        self.title = name
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
