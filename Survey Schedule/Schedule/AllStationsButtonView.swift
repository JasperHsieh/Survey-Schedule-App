//
//  AllStationsButtonView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/15/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI

struct AllStationsButtonView: View {
    var body: some View {
        Button(action: {
            print("click All Stations")
        }){
            VStack(){
                Image("All Stations Img")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 50, height: 50)
                Text("All Stations")
            }
        }
    }
}

struct AllStationsButtonView_Previews: PreviewProvider {
    static var previews: some View {
        AllStationsButtonView()
    }
}
