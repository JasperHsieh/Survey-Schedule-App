//
//  MasterButtonView.swift
//  Survey Schedule
//
//  Created by Jasper Hsieh on 3/15/20.
//  Copyright © 2020 Jasper Hsieh. All rights reserved.
//

import SwiftUI

struct MasterButtonView: View {
    var body: some View {
        Button(action: {
            print("click Master")
        }){
            VStack(){
                Image("Master Img")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 50, height: 50)
                Text("Master")
            }
        }
    }
}

struct MasterButtonView_Previews: PreviewProvider {
    static var previews: some View {
        MasterButtonView()
    }
}
