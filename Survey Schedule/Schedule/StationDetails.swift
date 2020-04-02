//
//  StationDetails.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 4/1/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI
import Foundation

struct StationDetails: View {
    var station: Station
    var isScheduled = true
    var body: some View {
        VStack {
            Text(station.name)
        }
    }
}
