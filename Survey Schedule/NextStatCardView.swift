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
                    Text(dynamicRouting.nextTravelTime)
                        //.frame(width:60)
                        .foregroundColor(.gray)
                }
                .frame(width: 90)
                //.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                Spacer()
                Spacer()
                //DoneButtonView()
                Button(action: doneAction){
                    Text(nextButton)
                        //.fontWeight(.bold)
                        .frame(minWidth: 50)
                        .font(.body)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(dynamicRouting.masterSchedule.count <= 0)
                .sheet(isPresented: $showingLoading) {
                    LoadingView().environmentObject(self.dynamicRouting)
                    //Text("Sheet")
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
        print("[NS] Click Done")
        self.showingLoading.toggle()
        //print("[NS] showingLoading: \(showingLoading)")
        //dynamicRouting.setPreStationVisited()
        if dynamicRouting.nextStation == BaseStation && dynamicRouting.beginDate == dynamicRouting.defaultTime {
            // Done fist station CS25
            dynamicRouting.reset()
            print("[NS] Update begin time \(dynamicRouting.beginDate)")
        }
        dynamicRouting.doneVisitStation()
    }
}


/*
struct NextStatCardView_Previews: PreviewProvider {
    static var previews: some View {
        NextStatCardView()
    }
}*/
