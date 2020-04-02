//
//  Station.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 4/1/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import Foundation
import CoreLocation

//struct Station: Hashable, Codable, Identifiable {
//    var id: Int
//    var name: String
//    fileprivate var imageName: String
//    fileprivate var coordinates: Coordinates
//    var state: String
//    var park: String
//    var category: Category
//
//    var locationCoordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(
//            latitude: coordinates.latitude,
//            longitude: coordinates.longitude)
//    }

//    enum Category: String, CaseIterable, Codable, Hashable {
//        case featured = "Featured"
//        case lakes = "Lakes"
//        case rivers = "Rivers"
//    }
//}

//extension Landmark {
//    var image: Image {
//        ImageStore.shared.image(name: imageName)
//    }
//}

struct Coordinates: Hashable, Codable {
    var latitude: Double
    var longitude: Double
}
