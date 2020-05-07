//
//  MasterButtonView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/15/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI
import SwiftDate
import CoreLocation

struct MasterButtonView: View {
    @State private var showingSheet = false
    @EnvironmentObject private var dynamicRouting: DynamicRouting

    var body: some View {
        Button(action: {
            print("[MB] click Master")
            self.showingSheet.toggle()
        }){
            VStack(){
                Image("Master Img")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 50, height: 50)
                Text("Master")
            }
        }.sheet(isPresented: $showingSheet) {
            ScheduleList().environmentObject(self.dynamicRouting)
        }
    }
}

struct ScheduleList: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dynamicRouting: DynamicRouting
    //var name: String
    //let dynamicRouting: DynamicRouting

//    init(routing dynamicRouting: DynamicRouting){
//        self.dynamicRouting = dynamicRouting
//    }

    var body: some View {
//        Button("Dismiss") {
//            self.presentationMode.wrappedValue.dismiss()
//        }
        NavigationView {
            List {
                ForEach(dynamicRouting.masterSchedule.indices, id: \.self) { day in
                    Section(header: Text("day \(day+1)")) {
                        ForEach(self.dynamicRouting.masterSchedule[day], id: \.self) { clusterSchedule in
                            ForEach(clusterSchedule, id: \.self) { visitLog in ScheduleRow(log: visitLog, isScheduled: self.dynamicRouting.isStationScheduled(station: visitLog.station)).environmentObject(self.dynamicRouting)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Master Schedule"))
            .navigationBarItems(trailing:
                Button(action: {
                    //print("Help tapped!")
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

struct ScheduleRow: View {
    //let dynamicRouting: DynamicRouting
    @EnvironmentObject private var dynamicRouting: DynamicRouting
    var log: VisitLog
    var stationIndex: Int {
        dynamicRouting.stationsList.firstIndex(where: {$0.name == log.station})!
    }
    var isScheduled: Bool
    //var station = Station(id: "-1", name: "CMU", image: "CMU", coordinate: CLLocationCoordinate2D(latitude: -1, longitude: -1))
    //let tmp = dynamicRouting.startTime! + log.timestamp.seconds
    //let timeStamp: String = "10:00:01"
    var body: some View {
        HStack {
            Spacer()
            //Text(String((self.dynamicRouting.beginDate + log.timestamp.seconds).toFormat("HH:mm")))
            Text(String((log.date).toFormat("HH:mm")))
                //.font(.system(size: 30))
                .frame(width:UIScreen.main.bounds.width * 0.4, alignment: .leading)
            Spacer()
            HStack{
                Text(log.station)
//                .frame(width:UIScreen.main.bounds.width * 0.4, alignment: .leading)
                if log.isRevisit {
                    Text("(Repeat)")
                        .foregroundColor(Color.gray)
                }
                if log.isSkip {
                    Text("(Skipped)")
                    .foregroundColor(Color.gray)
                }

            }.frame(width:UIScreen.main.bounds.width * 0.4, alignment: .leading)
            Spacer()
        }
        .foregroundColor((log.index < dynamicRouting.currentVisitPath.count) ? Color.gray: Color.primary)
        //.foregroundColor(dynamicRouting.stationsList[stationIndex].isVisited ? Color.gray: Color.primary)
    }
//    init(log: VisitLog) {
//        //self.dynamicRouting = dynamicRouting
//        self.log = log
//        let df = DateFormatter()
//        df.dateFormat = "hh:mm:ss"
//        //station = self.dynamicRouting.stationsList[self.dynamicRouting.getStationIndex(station: log.station)]
//        //timeStamp = df.string(from: dynamicRouting.startTime! + log.timestamp.seconds)
//        //timeStamp = (self.dynamicRouting.startTime! + log.timestamp.seconds).toFormat("HH:mm:ss")
//    }
}

//struct MasterButtonView_Previews: PreviewProvider {
//    static var previews: some View {
//        MasterButtonView()
//    }
//}
