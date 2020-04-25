//
//  StationDetails.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 4/1/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI
import Combine

struct StationDetails: View {
    //@State var isScheduled = true
    //let dynamicRouting: DynamicRouting
    @EnvironmentObject private var dynamicRouting: DynamicRouting
    @State var station: Station
    @State var name: String = ""
    @State private var keyboardHeight: CGFloat = 0

    var stationIndex: Int {
        dynamicRouting.stationsList.firstIndex(where: {$0.id == station.id})!
    }

    var body: some View {
        VStack {
            StationMapView(coordinate: station.coordinate, station: self.station)
                .edgesIgnoringSafeArea(.top)
                .frame(height: CGFloat(200))

            CircleImage(image: station.image)
                .offset(x: CGFloat(0), y: CGFloat(-80))
                .padding(.bottom, CGFloat(-110))

            VStack(alignment: .leading) {
                Text(station.name)
                    .font(.title)
                //Toggle(isOn: $isScheduled) {
                //Toggle(isOn: $station.isScheduled) {
                Toggle(isOn: $dynamicRouting.stationsList[stationIndex].isScheduled) {
                    Text("Include the station to schedule")
                    //dynamicRouting.test()
                }
                Divider()
                VStack(alignment: .leading){
                    Text("Notes")
                    TextField("Enter some text", text: $name)
                }

                //Text("\(name)")
            }
            .padding()
            Spacer()
        }
        .navigationBarTitle(Text(station.name), displayMode: .inline)
        .keyboardAdaptive()
    }
}
