//
//  MainView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/15/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI
struct MainView: View {
    @State private var position = CardPosition.middle
    @State private var background = BackgroundStyle.blur
    var dynamicRouting = DynamicRouting(Day: 1, PreStat: DynamicRouting.baseStat)
    //@EnvironmentObject private var dynamicRouting: DynamicRouting
    var body: some View {
        ZStack(alignment: Alignment.top) {
            MapView()
            SlideOverCard($position, backgroundStyle: $background) {
                VStack {
                    //Text("Slide Over Card").font(.title)
                    //Spacer()
                    NextStatCardView(routing: self.dynamicRouting)
                    ScheduleCardView().environmentObject(self.dynamicRouting)
                    TroublesCardView().environmentObject(self.dynamicRouting)
                }
            }
        }
        .edgesIgnoringSafeArea(.vertical)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
