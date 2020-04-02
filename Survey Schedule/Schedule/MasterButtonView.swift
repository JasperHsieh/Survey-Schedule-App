//
//  MasterButtonView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/15/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI
import SwiftDate

struct MasterButtonView: View {
    @State private var showingSheet = false
    let dynamicRouting: DynamicRouting

    init(routing dynamicRouting: DynamicRouting){
        self.dynamicRouting = dynamicRouting
    }

    var body: some View {
        Button(action: {
            print("click Master")
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
            ScheduleList(routing: self.dynamicRouting)
        }
    }
}

struct ScheduleList: View {
    @Environment(\.presentationMode) var presentationMode
    //var name: String
    let dynamicRouting: DynamicRouting

    init(routing dynamicRouting: DynamicRouting){
        self.dynamicRouting = dynamicRouting
    }

    var body: some View {
        //Text("Hello, \(dynamicRouting.schedule[1]![1].station)!")
//        Button("Dismiss") {
//            self.presentationMode.wrappedValue.dismiss()
//        }
        NavigationView {
            List(dynamicRouting.schedule[1] ?? []){ visitLog in ScheduleRow(dynamicRouting: self.dynamicRouting, log: visitLog)
            }
            .navigationBarTitle(Text("Master Schedule Today"))
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

struct ScheduleRow: View {
    let dynamicRouting: DynamicRouting
    var log: VisitLog
    //let tmp = dynamicRouting.startTime! + log.timestamp.seconds
    let timeStamp: String
    var body: some View {
        HStack {
            Spacer()
            Text(String(timeStamp))
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
            }.frame(width:UIScreen.main.bounds.width * 0.4, alignment: .leading)
            Spacer()
        }
    }
    init(dynamicRouting: DynamicRouting, log: VisitLog) {
        self.dynamicRouting = dynamicRouting
        self.log = log
        let df = DateFormatter()
        df.dateFormat = "hh:mm:ss"
        //tmp = df.string(from: dynamicRouting.startTime! + log.timestamp.seconds)
        timeStamp = (dynamicRouting.startTime! + log.timestamp.seconds).toFormat("HH:mm:ss")
    }
}

//struct MasterButtonView_Previews: PreviewProvider {
//    static var previews: some View {
//        MasterButtonView()
//    }
//}
