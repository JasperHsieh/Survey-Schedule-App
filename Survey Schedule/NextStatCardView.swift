//
//  NextStatCardView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/14/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI
import SwiftyJSON
import Combinatorics

struct NextStatCardView: View {
    @State var nextStation: String = DynamicRouting.baseStat
    @State var nextTravelTime: String = "1:00"
    //var dynamicRouting = DynamicRouting(Day: 1, PreStat: DynamicRouting.baseStat)
    let dynamicRouting: DynamicRouting
    let clusterRouting: ClusterRouting
    let stationRouting: StationRouting
    let dataUtil: DataUtil
    let timeLimit = 8*60*60

    init(routingInstance dynamicRouting: DynamicRouting){
        self.dynamicRouting = dynamicRouting
        self.stationRouting = StationRouting()
        self.dataUtil = DataUtil()
        self.clusterRouting = ClusterRouting(clusterInfo: DataUtil.clusterInfo!, workingTime: timeLimit)
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
                Spacer()
                VStack(alignment: .leading){
                    Text(nextStation).font(.headline)
                    Text(nextTravelTime).foregroundColor(.gray)
                }
                Spacer()
                Spacer()
                //DoneButtonView()
                Button(action: doneAction){
                    Text("Done")
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }

                Spacer()
            }.padding(.bottom)
        }
        .frame(width:UIScreen.main.bounds.width * 0.9/*, height: 200*/)
        .background(Color.white)
        .cornerRadius(10)
        .padding(.top)
    }
    func doneAction(){
        print("Click Done")
        clusterRouting.getNextDaySchedule(info: DataUtil.clusterInfo!, workingTime: timeLimit)
        //let statList = DataUtil.clusterInfo!["1"]["stations"].arrayObject
        //let statList = DataUtil.clusterInfo!["1"]["stations"].arrayValue.map {$0.stringValue}
        //print("statList: \(statList)")
        //let statList = ["RE3", "RE35", "RE2", "CS31", "RE40", "COSO3", "RE39"]
        //stationRouting.getMinTimePermutation(statList: statList)
        //stationRouting.getVisitPath(statList: statList as! [String], pathSoFar: [])
        //stationRouting.simulateVisitStations(statList: statList, pathSoFar: [])
        //let tmp = ["DOR39", "DOR38", "DOR37", "CS8"]
        //stationRouting.getTotalVisitTime(statList: tmp)
        //let time = dataUtil.getStatsTravelTime(stat1: statList[0], stat2: statList[1])
        //print("time: \(time)")
//        let tmpj: JSON = ["t1": "abc", "t2": "cdf"]
//        let k = "t1"
//        if tmpj[k].exists() {
//            print(tmpj[k])
//        }

    }
}


/*
struct NextStatCardView_Previews: PreviewProvider {
    static var previews: some View {
        NextStatCardView()
    }
}*/
