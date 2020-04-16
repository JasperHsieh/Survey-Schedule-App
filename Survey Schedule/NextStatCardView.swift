//
//  NextStatCardView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/14/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI
import SwiftyJSON
import SwiftDate
import Combinatorics

struct NextStatCardView: View {
    @EnvironmentObject private var dynamicRouting: DynamicRouting
    @State var nextButton: String = "Done"
    @State private var showingLoading = false

    let clusterRouting: ClusterRouting
    let stationRouting: StationRouting
    //let dataUtil: DataUtil
    let timeLimit = 8*60*60
    @Environment(\.colorScheme) var colorScheme
    //var isStarted = false
    //ar nextButton = "Start"

    init(){
        self.stationRouting = StationRouting()
        //self.dataUtil = DataUtil()
        self.clusterRouting = ClusterRouting(clusterInfo: clusterInfo!, workingTime: timeLimit)
    }

    var body: some View {
        VStack(){
            Text("Next Station")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                //.lineLimit(2)
                .frame(width: UIScreen.main.bounds.width * 0.8, /*height: 200,*/ alignment: .topLeading)
                .padding(.top)
            HStack(){
                //Image
                Spacer()
                Image("Next Station Img").resizable().frame(width: 50, height: 50)
                //Spacer()
                VStack(alignment: .leading){
                    Text(dynamicRouting.nextStation).font(.headline)
                    Text(dynamicRouting.nextTravelTime).foregroundColor(.gray)
                }
                .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))
                Spacer()
                Spacer()
                //DoneButtonView()
                Button(action: doneAction){
                    Text(nextButton)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }.sheet(isPresented: $showingLoading) {
                    LoadingView().environmentObject(self.dynamicRouting)
                }

                Spacer()
            }.padding(.bottom)
        }
        .frame(width:UIScreen.main.bounds.width * 0.9/*, height: 200*/)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(10)
        .padding(.top)
    }
    func doneAction(){
        print("Click Done")
        if dynamicRouting.nextStation == BaseStation && dynamicRouting.beginDate == dynamicRouting.defaultTime {
            // Done fist station CS25
            dynamicRouting.beginDate = getCurrentDate()
            dynamicRouting.lastRepeatTime = 0
            print("Update begin time \(dynamicRouting.beginDate)")
        }
        dynamicRouting.getNextStation()

        //var tmp1 = Date()
        //var tmp2 = tmp1.addingTimeInterval(60)
        //print("\(tmp1) \(tmp2)")


//        if !dynamicRouting.isStarted {
//            // Prepare for start
//            self.showingLoading.toggle()
//            dynamicRouting.isStarted = true
//            //makeSchedule()
////            let here = Region(calendar: Calendars.gregorian, zone: Zones.current, locale: Locales.englishUnitedStatesComputer)
//            //dynamicRouting.beginTime = DateInRegion(Date(), region: here)
//            //print(dynamicRouting.startTime)
//        } else {
//            // dynamic plan next station
//            if dynamicRouting.nextStation == BaseStation && dynamicRouting.beginTime == dynamicRouting.defaultTime {
//                // Done fist station CS25
//                dynamicRouting.beginTime = getCurrentDate()
//                dynamicRouting.lastRepeatTime = dynamicRouting.beginTime
//                print("Update begin time \(dynamicRouting.beginTime)")
//
//            }
//        }
    }

//    func makeSchedule() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            //print("This is run on the background queue")
//            self.dynamicRouting.makeRoutingSchedule(clusters: clusterInfo ?? JSON(), workintHour: WorkingHour, currentStat: BaseStation)
//            DispatchQueue.main.async {
//                //print("This is run on the main queue, after the previous code in outer block")
//                self.nextButton = "Done"
//                self.showingLoading.toggle()
//            }
//        }
//    }
}


/*
struct NextStatCardView_Previews: PreviewProvider {
    static var previews: some View {
        NextStatCardView()
    }
}*/
