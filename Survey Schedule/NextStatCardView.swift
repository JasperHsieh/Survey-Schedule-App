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
    @State var nextButton: String = "Start"
    @State private var showingLoading = false
    //var dynamicRouting = DynamicRouting(Day: 1, PreStat: DynamicRouting.baseStat)
    let dynamicRouting: DynamicRouting
    let clusterRouting: ClusterRouting
    let stationRouting: StationRouting
    //let dataUtil: DataUtil
    let timeLimit = 8*60*60
    @Environment(\.colorScheme) var colorScheme
    //var isStarted = false
    //ar nextButton = "Start"

    init(routing dynamicRouting: DynamicRouting){
        self.dynamicRouting = dynamicRouting
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
        print("Click Done \(Date())")
        if !dynamicRouting.isStarted {
            // Prepare for start
            self.showingLoading.toggle()
            dynamicRouting.isStarted = true
            makeSchedule()
            let here = Region(calendar: Calendars.gregorian, zone: Zones.current, locale: Locales.englishUnitedStatesComputer)
            //dynamicRouting.beginTime = DateInRegion(Date(), region: here)
            //print(dynamicRouting.startTime)
        } else {
            // dynamic plan next station
//            if dynamicRouting.nextStation == BaseStation && dynamicRouting.lastRepeatTime == dynamicRouting.defaultTime {
//                print("Update begin time")
//                print(Date().description(with: .current).toDate() )
//                print(Date().localString().toDate())
//            }
        }
    }

    func makeSchedule() {
        DispatchQueue.global(qos: .userInitiated).async {
            //print("This is run on the background queue")
            self.dynamicRouting.makeRoutingSchedule(clusters: clusterInfo ?? JSON(), workintHour: WorkingHour, currentStat: BaseStation)
            DispatchQueue.main.async {
                //print("This is run on the main queue, after the previous code in outer block")
                self.nextButton = "Done"
                self.showingLoading.toggle()
            }
        }
    }
}


/*
struct NextStatCardView_Previews: PreviewProvider {
    static var previews: some View {
        NextStatCardView()
    }
}*/
