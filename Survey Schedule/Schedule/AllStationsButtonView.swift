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
            StationList()
        }
    }
}

struct StationList: View {
    @Environment(\.presentationMode) var presentationMode
    //var stationList: [Station]
    var body: some View {

        NavigationView {
            List(stationsList) { station in
                NavigationLink(destination: StationDetails(station: station)) {
                    StationRow(station: station)
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
    var body: some View {
        HStack {
            Text(station.name)
        }
    }
}

struct AllStationsButtonView_Previews: PreviewProvider {
    static var previews: some View {
        AllStationsButtonView()
    }
}
