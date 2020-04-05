//
//  StationDetails.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 4/1/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI

struct StationDetails: View {
    //@State var isScheduled = true
    //let dynamicRouting: DynamicRouting
    @EnvironmentObject private var dynamicRouting: DynamicRouting
    @State var station: Station

    var stationIndex: Int {
        dynamicRouting.stationsList.firstIndex(where: {$0.id == station.id})!
    }

    var body: some View {
        VStack {
            StationMapView(coordinate: station.locationCoordinate)
                .edgesIgnoringSafeArea(.top)
                .frame(height: CGFloat(300))

            CircleImage(image: station.image)
                .offset(x: CGFloat(0), y: CGFloat(-130))
                .padding(.bottom, CGFloat(-130))

            VStack(alignment: .leading) {
                Text(station.name)
                    .font(.title)
                //Toggle(isOn: $isScheduled) {
                //Toggle(isOn: $station.isScheduled) {
                Toggle(isOn: $dynamicRouting.stationsList[stationIndex].isScheduled) {
                    Text("Include the station to schedule")
                    //dynamicRouting.test()
                }//.padding()
//                HStack(alignment: .top) {
//                    Text(station.park)
//                        .font(.subheadline)
//                    Spacer()
//                    Text(station.state)
//                        .font(.subheadline)
//                }
            }
            .padding()
            Spacer()

        }
        .navigationBarTitle(Text(station.name), displayMode: .inline)
    }
}
