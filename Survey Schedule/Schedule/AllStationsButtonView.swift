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
    @State private var showingAlert = false

    var body: some View {

        NavigationView {
            List(dynamicRouting.stationsList) { station in
                NavigationLink(destination: StationDetails(station: station).environmentObject(self.dynamicRouting)) {
                    StationRow(station: station).environmentObject(self.dynamicRouting)
                }
            }
            .navigationBarTitle(Text("All Stations"))
            .navigationBarItems(
                leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }, label: { Text("Cancel") }),

                trailing: Button(action: {
                    self.showingAlert = true
                }, label: { Text("Apply") })
                    .alert(isPresented:$showingAlert) {
                        Alert(title: Text("Are you sure you want to apply the stations?"), message: Text("It will take few minutes to reschedule"), primaryButton: .default(Text("Apply")) {
                                print("Apply...")
                            self.applyStationsChange()
                        }, secondaryButton: .cancel())
                    }
            )
        }
    }
//    func handleCancel(){
//        print("Click cancel")
//        self.presentationMode.wrappedValue.dismiss()
//    }
//
//    func handleApply(){
//        print("Click Apply")
//        self.showingAlert = true
//    }

    func applyStationsChange() {
        print("Apply stations change")
    }

}



struct NavigationCancelButton: View {
    @Binding var isPresented: Bool
    var body: some View {
        Button(action: {
            print("Click cancel")
        }) {
            Text("Cancel")
        }
    }
}

struct NavigationApplyButton: View {
    var body: some View {
        Button(action: {
            print("Click apply")
        }) {
            Text("Apply")
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
    }
}

//struct AllStationsButtonView_Previews: PreviewProvider {
//    static var previews: some View {
//        AllStationsButtonView()
//    }
//}
