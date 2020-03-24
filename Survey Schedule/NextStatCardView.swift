//
//  NextStatCardView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/14/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI

struct NextStatCardView: View {
    @State var nextStation: String = DynamicRouting.baseStat
    @State var nextTravelTime: String = "1:00"
    //var dynamicRouting = DynamicRouting(Day: 1, PreStat: DynamicRouting.baseStat)
    let dynamicRouting: DynamicRouting
    init(routingInstance dynamicRouting: DynamicRouting){
        self.dynamicRouting = dynamicRouting
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
        //nextStation = "North Park"
        nextStation = dynamicRouting.getNextStation(PreStat: nextStation)
    }
}


/*
struct NextStatCardView_Previews: PreviewProvider {
    static var previews: some View {
        NextStatCardView()
    }
}*/
