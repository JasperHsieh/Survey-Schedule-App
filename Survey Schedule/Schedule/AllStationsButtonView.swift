//
//  AllStationsButtonView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/15/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI

struct AllStationsButtonView: View {
    @State private var showingSheet = false
    @EnvironmentObject private var dynamicRouting: DynamicRouting
    //let dynamicRouting: DynamicRouting

//    init(routing dynamicRouting: DynamicRouting){
//        self.dynamicRouting = dynamicRouting
//    }
    
    var body: some View {
        Button(action: {
            print("click All Stations")
            self.showingSheet.toggle()
        }){
            VStack(){
                Image("All Stations Img")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 50, height: 50)
                Text("All Stations")
            }
        }.sheet(isPresented: $showingSheet) {
            StationList().environmentObject(self.dynamicRouting)
        }
    }
}

struct StationList: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dynamicRouting: DynamicRouting
    //let dynamicRouting: DynamicRouting

    var body: some View {

        NavigationView {
            List(dynamicRouting.stationsList) { station in
                NavigationLink(destination: StationDetails(station: station).environmentObject(self.dynamicRouting)) {
                    StationRow(station: station).environmentObject(self.dynamicRouting)
                }
            }
            .navigationBarTitle(Text("All Stations"))
            .navigationBarItems(trailing:
                Button(action: {
                    print("Help tapped!")
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image("Cancel Img")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 30, height: 30)
                }
            )
        }
    }

}

struct StationRow: View {
    var station: Station
    @EnvironmentObject private var dynamicRouting: DynamicRouting
    //var scheduling: String
    var body: some View {
        HStack {
            Spacer()
            Text(station.name)
                .frame(width:UIScreen.main.bounds.width * 0.4, alignment: .leading)
            Spacer()
            Spacer()
            if station.isScheduled {
                //print("\(station.name) \(station.isScheduled)")
                Text("Scheduled")
            } else {
                Text("Not Scheduled")
            }

            Spacer()
//            .frame(width:UIScreen.main.bounds.width * 0.4, alignment: .leading)
        }
    }

    init(station: Station) {
        self.station = station
//        if station.isScheduled {
//            scheduling = "Scheduled"
//        } else {
//            scheduling = "Not Scheduled"
//        }
    }
}

//struct AllStationsButtonView_Previews: PreviewProvider {
//    static var previews: some View {
//        AllStationsButtonView()
//    }
//}
